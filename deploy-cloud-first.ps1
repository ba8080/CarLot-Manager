# Car Lot Manager - Cloud-First Deployment (Windows)
#
# Teacher only needs:
#   ✓ AWS CLI
#   ✓ AWS Credentials
#   ✓ This script
#
# Everything else (Terraform, Ansible, kubectl, Helm) 
# is installed ON the AWS master node

param(
    [string]$Region = "us-east-1"
)

# Color output
function Write-Header {
    param([string]$Message)
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host $Message -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Success {
    param([string]$Message)
    Write-Host "[✓] $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "[✗] $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host "[•] $Message" -ForegroundColor Yellow
}

# Set script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  🚗 CAR LOT MANAGER - CLOUD-FIRST DEPLOYMENT 🚗           ║" -ForegroundColor Cyan
Write-Host "║                                                            ║" -ForegroundColor Cyan
Write-Host "║  Teacher needs ONLY: AWS CLI + AWS Credentials            ║" -ForegroundColor Cyan
Write-Host "║  Everything else installs ON CLOUD                        ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# ============================================
# STEP 0: Check Prerequisites
# ============================================
Write-Header "STEP 0: Checking Prerequisites"

Write-Info "Checking AWS CLI..."
if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
    Write-Error "AWS CLI not found"
    Write-Host ""
    Write-Host "Install from: https://aws.amazon.com/cli/"
    Write-Host ""
    exit 1
}

$AwsVersion = aws --version
Write-Success "AWS CLI installed: $AwsVersion"

Write-Info "Checking AWS credentials..."
$AwsCheck = aws sts get-caller-identity 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "AWS credentials not valid"
    Write-Host "Please configure AWS credentials:"
    Write-Host "  1. Edit aws_credentials with your AWS keys"
    Write-Host "  2. Or run: aws configure"
    exit 1
}

Write-Success "AWS credentials valid"
Write-Success "AWS Account ID: $(($AwsCheck | ConvertFrom-Json).Account)"

# ============================================
# STEP 1: Create SSH Key Pair
# ============================================
Write-Header "STEP 1: Creating SSH Key Pair on AWS"

$KeyName = "car-lot-deployer-$(Get-Date -Format 'yyyyMMddHHmmss')"
Write-Info "Creating key pair: $KeyName"

$KeyOutput = aws ec2 create-key-pair `
    --key-name $KeyName `
    --region $Region `
    --query 'KeyMaterial' `
    --output text

$KeyOutput | Out-File -FilePath "$KeyName.pem" -Encoding UTF8
Write-Success "Key pair created: $KeyName.pem"
Write-Info "Keep this key file safe - you need it to SSH into the master node"

# ============================================
# STEP 2: Create Security Group
# ============================================
Write-Header "STEP 2: Creating Security Group on AWS"

$SgName = "car-lot-manager"
Write-Info "Checking if security group exists: $SgName"

# Create VPC first if needed
$VpcId = aws ec2 describe-vpcs --query 'Vpcs[0].VpcId' --output text --region $Region

$SgCheck = aws ec2 describe-security-groups `
    --group-names $SgName `
    --region $Region 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Success "Security group already exists"
} else {
    Write-Info "Creating security group..."
    
    $SgId = aws ec2 create-security-group `
        --group-name $SgName `
        --description "Car Lot Manager security group" `
        --vpc-id $VpcId `
        --region $Region `
        --query 'GroupId' `
        --output text
    
    Write-Success "Security group created: $SgId"
    
    # Add inbound rules
    Write-Info "Adding inbound rules..."
    
    # SSH from anywhere (allow for debugging)
    aws ec2 authorize-security-group-ingress `
        --group-id $SgId `
        --protocol tcp `
        --port 22 `
        --cidr 0.0.0.0/0 `
        --region $Region 2>&1 | Out-Null
    
    # HTTP
    aws ec2 authorize-security-group-ingress `
        --group-id $SgId `
        --protocol tcp `
        --port 80 `
        --cidr 0.0.0.0/0 `
        --region $Region 2>&1 | Out-Null
    
    # HTTPS
    aws ec2 authorize-security-group-ingress `
        --group-id $SgId `
        --protocol tcp `
        --port 443 `
        --cidr 0.0.0.0/0 `
        --region $Region 2>&1 | Out-Null
    
    # Kubernetes API
    aws ec2 authorize-security-group-ingress `
        --group-id $SgId `
        --protocol tcp `
        --port 6443 `
        --cidr 10.0.0.0/8 `
        --region $Region 2>&1 | Out-Null
    
    # NFS
    aws ec2 authorize-security-group-ingress `
        --group-id $SgId `
        --protocol tcp `
        --port 2049 `
        --cidr 10.0.0.0/8 `
        --region $Region 2>&1 | Out-Null
    
    Write-Success "Inbound rules configured"
}

# ============================================
# STEP 3: Launch Master Node with Bootstrap
# ============================================
Write-Header "STEP 3: Launching Master Node on AWS"

# Bootstrap script
$BootstrapScript = @'
#!/bin/bash
set -e

echo "=========================================="
echo "BOOTSTRAP: Installing DevOps Tools"
echo "=========================================="

# Update system
sudo apt-get update -y
sudo apt-get upgrade -y

# Install dependencies
sudo apt-get install -y wget unzip curl git python3-pip jq

# Install Docker
echo "[1/5] Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker ubuntu
rm get-docker.sh

# Install Terraform
echo "[2/5] Installing Terraform..."
wget -q https://releases.hashicorp.com/terraform/1.5.0/terraform_1.5.0_linux_amd64.zip
unzip -q terraform_1.5.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/
rm terraform_1.5.0_linux_amd64.zip

# Install kubectl
echo "[3/5] Installing kubectl..."
curl -LOs https://dl.k8s.io/release/v1.27.0/bin/linux/amd64/kubectl
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

# Install Helm
echo "[4/5] Installing Helm..."
curl -fsSL https://get.helm.sh/helm-v3.12.0-linux-amd64.tar.gz -o helm.tar.gz
tar -xzf helm.tar.gz
sudo mv linux-amd64/helm /usr/local/bin/
rm -rf helm.tar.gz linux-amd64

# Install Ansible
echo "[5/5] Installing Ansible..."
sudo pip3 install ansible -q

echo ""
echo "=========================================="
echo "✅ DevOps tools installation complete!"
echo "=========================================="
'@

# Convert to base64
$BootstrapBytes = [System.Text.Encoding]::UTF8.GetBytes($BootstrapScript)
$BootstrapB64 = [System.Convert]::ToBase64String($BootstrapBytes)

Write-Info "Launching t2.medium instance in $Region..."

$InstanceJson = aws ec2 run-instances `
    --image-id ami-0c55b159cbfafe1f0 `
    --instance-type t2.medium `
    --key-name $KeyName `
    --security-groups $SgName `
    --user-data $BootstrapB64 `
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=CarLot-Master}]" `
    --region $Region

$InstanceId = ($InstanceJson | ConvertFrom-Json).Instances[0].InstanceId
Write-Success "Instance launched: $InstanceId"

Write-Info "Waiting for instance to be running..."
aws ec2 wait instance-running `
    --instance-ids $InstanceId `
    --region $Region

# Get instance details
$InstanceInfo = aws ec2 describe-instances `
    --instance-ids $InstanceId `
    --region $Region | ConvertFrom-Json

$PublicIp = $InstanceInfo.Reservations[0].Instances[0].PublicIpAddress
$PrivateIp = $InstanceInfo.Reservations[0].Instances[0].PrivateIpAddress

Write-Success "Instance is running!"
Write-Info "Public IP: $PublicIp"
Write-Info "Private IP: $PrivateIp"

# ============================================
# STEP 4: Wait for Bootstrap & SSH Ready
# ============================================
Write-Header "STEP 4: Waiting for Bootstrap & SSH Ready"

Write-Info "Waiting for SSH to be ready (this may take 2-3 minutes)..."

$maxAttempts = 30
$attempt = 0

while ($attempt -lt $maxAttempts) {
    try {
        # Try to SSH
        $null = ssh -i "$KeyName.pem" `
            -o StrictHostKeyChecking=no `
            -o UserKnownHostsFile=/dev/null `
            -o ConnectTimeout=5 `
            -o BatchMode=yes `
            "ubuntu@$PublicIp" "echo 'ready'" 2>/dev/null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "SSH connection established"
            break
        }
    } catch {
        # Continue waiting
    }
    
    $attempt++
    Write-Info "Waiting... (Attempt $attempt/$maxAttempts)"
    Start-Sleep -Seconds 10
}

if ($attempt -eq $maxAttempts) {
    Write-Error "SSH timeout after 5 minutes"
    exit 1
}

Write-Info "Checking for DevOps tools installation..."
Write-Info "This may take 10-15 minutes..."

$toolAttempt = 0
$maxToolAttempts = 90

while ($toolAttempt -lt $maxToolAttempts) {
    try {
        $output = ssh -i "$KeyName.pem" `
            -o StrictHostKeyChecking=no `
            -o UserKnownHostsFile=/dev/null `
            -o ConnectTimeout=5 `
            -o BatchMode=yes `
            "ubuntu@$PublicIp" "terraform version && helm version && kubectl version --client" 2>/dev/null
        
        if ($output) {
            Write-Success "All DevOps tools installed on master node!"
            break
        }
    } catch {
        # Continue waiting
    }
    
    $toolAttempt++
    Write-Host -NoNewline "."
    Start-Sleep -Seconds 10
}

Write-Host ""

if ($toolAttempt -eq $maxToolAttempts) {
    Write-Error "Tools installation timeout"
    exit 1
}

# ============================================
# STEP 5: SUCCESS!
# ============================================
Write-Header "🎉 MASTER NODE IS READY!"

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  ✅ Master node deployed and tools installed!             ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

Write-Host @"

🌐 MASTER NODE ACCESS:
   Public IP: $PublicIp
   Private IP: $PrivateIp
   SSH Key: $KeyName.pem

🔧 INSTALLED TOOLS (on master):
   ✓ Docker
   ✓ Terraform
   ✓ kubectl
   ✓ Helm
   ✓ Ansible

📝 WHAT'S NEXT:
   1. Teacher next step: Deploy remaining infrastructure from master node
   2. Command: ssh -i $KeyName.pem ubuntu@$PublicIp
   3. On master: Run deployment commands to:
      - Initialize Kubernetes
      - Deploy NFS storage
      - Deploy application with Helm

⏱️  Bootstrap complete! Master node is ready.

🔐 IMPORTANT: Keep $KeyName.pem safe!
   This is your SSH key to access the master node.

"@
