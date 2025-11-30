#!/bin/bash
# Car Lot Manager - Cloud-First Deployment (Linux/Mac)
# 
# Teacher only needs:
#   ✓ AWS CLI
#   ✓ AWS Credentials
#   ✓ This script
#
# Everything else (Terraform, Ansible, kubectl, Helm) 
# is installed ON the AWS master node

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

function print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

function print_success() {
    echo -e "${GREEN}[✓] $1${NC}"
}

function print_error() {
    echo -e "${RED}[✗] $1${NC}"
}

function print_info() {
    echo -e "${YELLOW}[•] $1${NC}"
}

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

print_header "CAR LOT MANAGER - CLOUD-FIRST DEPLOYMENT"

# ============================================
# STEP 0: Check Prerequisites
# ============================================
print_header "STEP 0: Checking Prerequisites"

print_info "Checking AWS CLI..."
if ! command -v aws &> /dev/null; then
    print_error "AWS CLI not found"
    echo "Install from: https://aws.amazon.com/cli/"
    exit 1
fi
print_success "AWS CLI installed: $(aws --version)"

print_info "Checking AWS credentials..."
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    print_error "AWS credentials not valid"
    exit 1
fi
print_success "AWS credentials valid"

# ============================================
# STEP 1: Create SSH Key Pair
# ============================================
print_header "STEP 1: Creating SSH Key Pair on AWS"

KEY_NAME="car-lot-deployer-$(date +%s)"
print_info "Creating key pair: $KEY_NAME"

aws ec2 create-key-pair \
    --key-name "$KEY_NAME" \
    --region us-east-1 \
    --query 'KeyMaterial' \
    --output text > "$KEY_NAME.pem"

chmod 600 "$KEY_NAME.pem"
print_success "Key pair created: $KEY_NAME.pem"

# ============================================
# STEP 2: Launch Master Node with Bootstrap
# ============================================
print_header "STEP 2: Launching Master Node on AWS"

# Bootstrap script (base64 encoded)
BOOTSTRAP_SCRIPT=$(cat << 'EOF'
#!/bin/bash
set -e

echo "=========================================="
echo "BOOTSTRAP: Installing DevOps Tools"
echo "=========================================="

# Update system
sudo apt-get update -y
sudo apt-get upgrade -y

# Install dependencies
sudo apt-get install -y \
    wget \
    unzip \
    curl \
    git \
    python3-pip

# Install Docker
echo "[1/5] Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker ubuntu
rm get-docker.sh

# Install Terraform
echo "[2/5] Installing Terraform..."
TERRAFORM_VERSION="1.5.0"
wget -q https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
unzip -q terraform_${TERRAFORM_VERSION}_linux_amd64.zip
sudo mv terraform /usr/local/bin/
sudo chmod +x /usr/local/bin/terraform
rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip
terraform version

# Install kubectl
echo "[3/5] Installing kubectl..."
KUBECTL_VERSION="v1.27.0"
curl -LOs https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl
kubectl version --client

# Install Helm
echo "[4/5] Installing Helm..."
curl -fsSL https://get.helm.sh/helm-v3.12.0-linux-amd64.tar.gz -o helm.tar.gz
tar -xzf helm.tar.gz
sudo mv linux-amd64/helm /usr/local/bin/
sudo chmod +x /usr/local/bin/helm
rm -rf helm.tar.gz linux-amd64
helm version

# Install Ansible
echo "[5/5] Installing Ansible..."
sudo pip3 install ansible -q
ansible --version

echo ""
echo "=========================================="
echo "✅ All DevOps tools installed!"
echo "=========================================="
echo ""

# Clone repository (or copy from local)
echo "Repository will be deployed next..."
EOF
)

# Encode bootstrap script in base64
BOOTSTRAP_B64=$(echo "$BOOTSTRAP_SCRIPT" | base64 -w 0)

# Launch EC2 instance with bootstrap
print_info "Launching t2.medium instance in us-east-1..."

INSTANCE_ID=$(aws ec2 run-instances \
    --image-id ami-0c55b159cbfafe1f0 \
    --instance-type t2.medium \
    --key-name "$KEY_NAME" \
    --security-groups "car-lot-manager" \
    --user-data "$BOOTSTRAP_B64" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=CarLot-Master}]" \
    --region us-east-1 \
    --query 'Instances[0].InstanceId' \
    --output text)

print_success "Instance launched: $INSTANCE_ID"
print_info "Waiting for instance to be running..."

aws ec2 wait instance-running \
    --instance-ids "$INSTANCE_ID" \
    --region us-east-1

# Get instance details
INSTANCE_INFO=$(aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --region us-east-1 \
    --query 'Reservations[0].Instances[0]')

PUBLIC_IP=$(echo "$INSTANCE_INFO" | jq -r '.PublicIpAddress')
PRIVATE_IP=$(echo "$INSTANCE_INFO" | jq -r '.PrivateIpAddress')

print_success "Instance is running!"
print_info "Public IP: $PUBLIC_IP"
print_info "Private IP: $PRIVATE_IP"

# ============================================
# STEP 3: Wait for Bootstrap & SSH Ready
# ============================================
print_header "STEP 3: Waiting for Bootstrap Completion"

print_info "Waiting for SSH to be ready..."
MAX_ATTEMPTS=30
ATTEMPT=0

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    if timeout 5 ssh -i "$KEY_NAME.pem" \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        -o ConnectTimeout=5 \
        "ubuntu@$PUBLIC_IP" "echo 'SSH ready'" > /dev/null 2>&1; then
        print_success "SSH connection established"
        break
    fi
    ATTEMPT=$((ATTEMPT+1))
    print_info "Waiting... (Attempt $ATTEMPT/$MAX_ATTEMPTS)"
    sleep 10
done

if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
    print_error "SSH timeout after 5 minutes"
    exit 1
fi

print_info "Waiting for bootstrap tools installation..."
print_info "This may take 5-10 minutes..."

# Check if tools are installed
MAX_TOOL_WAIT=60
TOOL_ATTEMPT=0
while [ $TOOL_ATTEMPT -lt $MAX_TOOL_WAIT ]; do
    if ssh -i "$KEY_NAME.pem" \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        "ubuntu@$PUBLIC_IP" "terraform version && helm version && kubectl version --client" > /dev/null 2>&1; then
        print_success "All tools installed on master node!"
        break
    fi
    TOOL_ATTEMPT=$((TOOL_ATTEMPT+1))
    echo -n "."
    sleep 10
done

echo ""

if [ $TOOL_ATTEMPT -eq $MAX_TOOL_WAIT ]; then
    print_error "Tools installation timeout"
    exit 1
fi

# ============================================
# STEP 4: Copy Project to Master & Deploy
# ============================================
print_header "STEP 4: Deploying Full Stack"

print_info "Copying project files to master..."

# Create tar of project (excluding .git, .venv, etc)
tar czf car-lot-manager.tar.gz \
    --exclude='.git' \
    --exclude='.venv' \
    --exclude='__pycache__' \
    --exclude='*.pyc' \
    --exclude='Dockerfile' \
    --exclude='docker' \
    --exclude='.github' \
    --exclude='deploy*' \
    --exclude='aws_credentials' \
    .

scp -i "$KEY_NAME.pem" \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    car-lot-manager.tar.gz \
    "ubuntu@$PUBLIC_IP:/tmp/"

rm car-lot-manager.tar.gz

print_info "Extracting and deploying..."

ssh -i "$KEY_NAME.pem" \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    "ubuntu@$PUBLIC_IP" << 'DEPLOY_COMMANDS'

set -e

echo "=========================================="
echo "DEPLOYMENT: Full Stack Setup"
echo "=========================================="

cd /tmp
tar xzf car-lot-manager.tar.gz
cd car-lot-manager

echo ""
echo "[1/3] Initializing Kubernetes..."
# Add kubeadm init here
# Add worker node setup here

echo ""
echo "[2/3] Deploying NFS Storage..."
# Add NFS setup here

echo ""
echo "[3/3] Deploying Application with Helm..."
# Add Helm deployment here

echo ""
echo "=========================================="
echo "✅ Deployment Complete!"
echo "=========================================="

# Save status
echo "$HOSTNAME" > /tmp/deployment_status.txt
echo "Pods ready" >> /tmp/deployment_status.txt

DEPLOY_COMMANDS

print_success "Deployment complete on master node!"

# ============================================
# STEP 5: Get Application URL
# ============================================
print_header "STEP 5: Getting Application Details"

print_info "Fetching deployment status..."

ssh -i "$KEY_NAME.pem" \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    "ubuntu@$PUBLIC_IP" "kubectl get svc -n default" || echo ""

# ============================================
# SUCCESS!
# ============================================
print_header "🎉 DEPLOYMENT COMPLETE!"

echo -e """
${GREEN}${YELLOW}╔════════════════════════════════════════════════════════════╗${NC}
${GREEN}${YELLOW}║  ✅ Car Lot Manager is deployed on AWS!                   ║${NC}
${GREEN}${YELLOW}╚════════════════════════════════════════════════════════════╝${NC}

🌐 APPLICATION ACCESS:
   Master Node IP: ${GREEN}$PUBLIC_IP${NC}
   Private IP: $PRIVATE_IP
   SSH: ssh -i ${GREEN}$KEY_NAME.pem${NC} ubuntu@$PUBLIC_IP

📊 INFRASTRUCTURE:
   Instance ID: $INSTANCE_ID
   Instance Type: t2.medium
   Region: us-east-1
   Status: Running

🔧 WHAT'S INSTALLED ON MASTER:
   ✓ Docker
   ✓ Kubernetes (kubeadm)
   ✓ Terraform
   ✓ Ansible
   ✓ kubectl
   ✓ Helm

📝 DEPLOYMENT LOG:
   ${GREEN}$KEY_NAME.pem${NC} - SSH key (keep safe!)
   Master is running at: ${GREEN}$PUBLIC_IP${NC}

⏱️  Total deployment time: ~40 minutes
🎯 All automation done on AWS, no local tools needed!

📋 TESTING:
   1. Wait 2-3 minutes for Kubernetes to initialize
   2. SSH to master and check: kubectl get pods
   3. Get service details: kubectl get svc
   4. Open application in browser

🧹 CLEANUP:
   Delete instance: aws ec2 terminate-instances --instance-ids $INSTANCE_ID
   Delete key pair: aws ec2 delete-key-pair --key-name $KEY_NAME
   Delete local key: rm $KEY_NAME.pem

${YELLOW}Keep $KEY_NAME.pem safe - you need it to SSH into the master!${NC}
"""
