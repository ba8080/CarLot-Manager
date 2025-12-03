#!/bin/bash

# Car Lot Manager - One-Command Deployment Script
# This script provisions AWS infrastructure and deploys the application
# Usage: ./deploy.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Helper functions
write_header() {
    echo ""
    echo -e "${CYAN}========================================"
    echo -e "$1"
    echo -e "========================================${NC}"
    echo ""
}

write_success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

write_error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

write_info() {
    echo -e "${YELLOW}[INFO] $1${NC}"
}

# Set script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Step 0: Check Prerequisites
write_header "CHECKING PREREQUISITES"

MISSING_TOOLS=()

for tool in terraform ansible kubectl helm; do
    if command -v $tool &> /dev/null; then
        write_success "$tool is installed"
    else
        write_error "$tool is NOT installed"
        MISSING_TOOLS+=("$tool")
    fi
done

if [ ${#MISSING_TOOLS[@]} -gt 0 ]; then
    write_error "Missing tools: ${MISSING_TOOLS[*]}"
    echo ""
    echo "Please install the required tools:"
    echo "  - Terraform: https://www.terraform.io/downloads"
    echo "  - Ansible: https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html"
    echo "  - kubectl: https://kubernetes.io/docs/tasks/tools/"
    echo "  - Helm: https://helm.sh/docs/intro/install/"
    echo ""
    exit 1
fi

# Step 1: Configure AWS Credentials
write_header "STEP 1: AWS CREDENTIALS CONFIGURATION"

AWS_CREDS_FILE="$SCRIPT_DIR/aws_credentials"

if [ ! -f "$AWS_CREDS_FILE" ]; then
    write_info "aws_credentials file not found"
    write_info "Creating template file..."
    
    cat > "$AWS_CREDS_FILE" << EOF
[default]
aws_access_key_id=YOUR_ACCESS_KEY_ID
aws_secret_access_key=YOUR_SECRET_ACCESS_KEY
aws_session_token=YOUR_SESSION_TOKEN
EOF
    
    write_info "Template created at: $AWS_CREDS_FILE"
    write_error "Please edit aws_credentials with your AWS credentials"
    exit 1
fi

# Parse aws_credentials file
AWS_ACCESS_KEY_ID=$(grep "aws_access_key_id" "$AWS_CREDS_FILE" | cut -d'=' -f2 | xargs)
AWS_SECRET_ACCESS_KEY=$(grep "aws_secret_access_key" "$AWS_CREDS_FILE" | cut -d'=' -f2 | xargs)
AWS_SESSION_TOKEN=$(grep "aws_session_token" "$AWS_CREDS_FILE" | cut -d'=' -f2 | xargs)

# Validate credentials are not placeholders
if [[ "$AWS_ACCESS_KEY_ID" == *"YOUR"* ]] || [[ "$AWS_SECRET_ACCESS_KEY" == *"YOUR"* ]]; then
    write_error "AWS credentials not configured. Please edit aws_credentials file"
    echo ""
    echo "Edit this file: $AWS_CREDS_FILE"
    echo "Add your AWS credentials (Access Key ID, Secret Access Key, and optionally Session Token)"
    echo ""
    exit 1
fi

write_success "AWS credentials configured"
export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY
[ -n "$AWS_SESSION_TOKEN" ] && export AWS_SESSION_TOKEN

# Step 2: Initialize and Apply Terraform
write_header "STEP 2: PROVISIONING INFRASTRUCTURE WITH TERRAFORM"

TERRAFORM_DIR="$SCRIPT_DIR/terraform"
cd "$TERRAFORM_DIR"

write_info "Initializing Terraform..."
terraform init

write_info "Applying Terraform configuration..."
terraform apply -auto-approve

write_success "Infrastructure provisioned successfully"

# Get outputs
write_info "Retrieving infrastructure details..."
ALB_DNS=$(terraform output -raw alb_dns_name)
MASTER_IP=$(terraform output -json instance_ips | jq -r '.[0]')
WORKER1_IP=$(terraform output -json instance_ips | jq -r '.[1]')
WORKER2_IP=$(terraform output -json instance_ips | jq -r '.[2]')
MASTER_PRIVATE_IP=$(terraform output -raw master_private_ip)
SSH_KEY=$(terraform output -raw ssh_private_key)

# Save SSH key to file
KEY_FILE="$SCRIPT_DIR/generated_key.pem"
echo "$SSH_KEY" > "$KEY_FILE"
chmod 600 "$KEY_FILE"
write_success "SSH key saved to: $KEY_FILE"

cd "$SCRIPT_DIR"

# Step 3: Wait for instances to be ready
write_header "STEP 3: WAITING FOR EC2 INSTANCES TO BE READY"

write_info "Waiting for instances to accept SSH connections..."

for ip in "$MASTER_IP" "$WORKER1_IP" "$WORKER2_IP"; do
    ATTEMPT=0
    MAX_ATTEMPTS=30
    READY=false
    
    while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
        if timeout 5 ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no -o ConnectTimeout=5 "ubuntu@$ip" exit 2>/dev/null; then
            write_success "Instance $ip is ready for SSH"
            READY=true
            break
        fi
        
        ATTEMPT=$((ATTEMPT + 1))
        write_info "Waiting for $ip... (attempt $ATTEMPT/$MAX_ATTEMPTS)"
        sleep 10
    done
    
    if [ "$READY" = false ]; then
        write_error "Instance $ip did not become ready in time"
        exit 1
    fi
done

# Step 4: Create Ansible Inventory
write_header "STEP 4: CONFIGURING ANSIBLE"

INVENTORY_FILE="$SCRIPT_DIR/ansible/inventory.ini"

cat > "$INVENTORY_FILE" << EOF
[master]
$MASTER_IP ansible_user=ubuntu ansible_ssh_private_key_file=$KEY_FILE ansible_ssh_common_args='-o StrictHostKeyChecking=no -o ConnectTimeout=10'

[worker]
$WORKER1_IP ansible_user=ubuntu ansible_ssh_private_key_file=$KEY_FILE ansible_ssh_common_args='-o StrictHostKeyChecking=no -o ConnectTimeout=10'
$WORKER2_IP ansible_user=ubuntu ansible_ssh_private_key_file=$KEY_FILE ansible_ssh_common_args='-o StrictHostKeyChecking=no -o ConnectTimeout=10'

[all:vars]
ansible_python_interpreter=/usr/bin/python3
EOF

write_success "Ansible inventory created"

# Step 5: Run Ansible Playbook
write_header "STEP 5: CONFIGURING KUBERNETES AND NFS WITH ANSIBLE"

cd "$SCRIPT_DIR/ansible"

write_info "Running Ansible playbook (this may take 5-10 minutes)..."
export ANSIBLE_HOST_KEY_CHECKING=False
ansible-playbook playbook.yml -i inventory.ini

if [ $? -ne 0 ]; then
    write_error "Ansible playbook failed"
    echo ""
    echo "You can manually retry with:"
    echo "  cd $SCRIPT_DIR/ansible"
    echo "  ansible-playbook playbook.yml -i inventory.ini -vvv"
    exit 1
fi

write_success "Kubernetes cluster and NFS configured successfully"
cd "$SCRIPT_DIR"

# Step 6: Fetch and Configure kubeconfig
write_header "STEP 6: PREPARING KUBERNETES ACCESS"

KUBECONFIG_PATH="$SCRIPT_DIR/kubeconfig"

write_info "Fetching kubeconfig from master node..."

ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no -o ConnectTimeout=10 "ubuntu@$MASTER_IP" \
    "cat /home/ubuntu/.kube/config" > "$KUBECONFIG_PATH"

# Update server address in kubeconfig to use public IP
sed -i.bak "s|server: https://[^:]*:6443|server: https://$MASTER_IP:6443|g" "$KUBECONFIG_PATH"
rm -f "$KUBECONFIG_PATH.bak"

write_success "kubeconfig saved to: $KUBECONFIG_PATH"

# Step 7: Deploy with Helm
write_header "STEP 7: DEPLOYING APPLICATION WITH HELM"

export KUBECONFIG="$KUBECONFIG_PATH"

write_info "Adding application to Kubernetes cluster..."
write_info "Using Docker image: azexkush/car-lot-manager:latest"
write_info "Using NFS server: $MASTER_PRIVATE_IP"

helm upgrade --install car-lot-manager ./helm/car-lot \
    --set nfs.server="$MASTER_PRIVATE_IP" \
    --kubeconfig="$KUBECONFIG_PATH" \
    --wait --timeout 15m

if [ $? -ne 0 ]; then
    write_error "Helm deployment failed"
    echo ""
    echo "You can retry with:"
    echo "  helm upgrade --install car-lot-manager ./helm/car-lot --set nfs.server=$MASTER_PRIVATE_IP --kubeconfig=$KUBECONFIG_PATH"
    exit 1
fi

write_success "Application deployed successfully with Helm"

# Step 8: Wait for deployment to be ready
write_header "STEP 8: WAITING FOR APPLICATION TO BE READY"

write_info "Waiting for application pods to be ready (this may take a few minutes)..."

COUNTER=0
MAX_WAIT=300  # 5 minutes

while [ $COUNTER -lt $MAX_WAIT ]; do
    READY_REPLICAS=$(kubectl get deployment car-lot-manager -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
    DESIRED_REPLICAS=$(kubectl get deployment car-lot-manager -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "0")
    
    if [ "$READY_REPLICAS" = "$DESIRED_REPLICAS" ] && [ -n "$DESIRED_REPLICAS" ] && [ "$DESIRED_REPLICAS" != "0" ]; then
        write_success "All application pods are ready"
        break
    fi
    
    write_info "Ready replicas: $READY_REPLICAS/$DESIRED_REPLICAS. Waiting..."
    sleep 15
    COUNTER=$((COUNTER + 15))
done

# Final Summary
write_header "DEPLOYMENT COMPLETE! SUCCESS!"

echo ""
echo -e "${GREEN}========================================"
echo -e "YOUR APPLICATION IS NOW LIVE!"
echo -e "========================================${NC}"
echo ""

echo -e "${CYAN}APPLICATION ACCESS:${NC}"
echo -e "${GREEN}  URL: http://$ALB_DNS${NC}"
echo ""

echo -e "${CYAN}INFRASTRUCTURE DETAILS:${NC}"
echo -e "${NC}  Master Node (public IP):      $MASTER_IP"
echo -e "  Master Node (private IP):     $MASTER_PRIVATE_IP"
echo -e "  Worker 1 (public IP):         $WORKER1_IP"
echo -e "  Worker 2 (public IP):         $WORKER2_IP"
echo -e "  Load Balancer DNS:            $ALB_DNS"
echo ""

echo -e "${CYAN}FILES:${NC}"
echo -e "  SSH Key:                      $KEY_FILE"
echo -e "  Kubeconfig:                   $KUBECONFIG_PATH"
echo -e "  Ansible Inventory:            $INVENTORY_FILE"
echo ""

echo -e "${CYAN}USEFUL COMMANDS:${NC}"
echo -e "  Check pod status:             kubectl get pods --kubeconfig=$KUBECONFIG_PATH"
echo -e "  View pod logs:                kubectl logs -l app=car-lot-manager --kubeconfig=$KUBECONFIG_PATH"
echo -e "  SSH to master:                ssh -i '$KEY_FILE' ubuntu@$MASTER_IP"
echo -e "  Access dashboard:             http://$ALB_DNS"
echo ""

echo -e "${CYAN}NEXT STEPS:${NC}"
echo -e "  1. Open browser: http://$ALB_DNS"
echo -e "  2. You should see the Car Lot Manager application"
echo -e "  3. Sample cars are already loaded (Toyota, Honda, Ford)"
echo -e "  4. Try adding, selling, or removing cars"
echo ""

echo -e "${CYAN}TO CLEAN UP INFRASTRUCTURE:${NC}"
echo -e "  cd terraform"
echo -e "  terraform destroy -auto-approve"
echo ""

echo -e "${GREEN}========================================"
echo -e "Happy testing! Contact admin for support."
echo -e "========================================${NC}"
echo ""