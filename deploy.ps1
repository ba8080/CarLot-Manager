# Car Lot Manager - One-Command Deployment Script
# This script provisions AWS infrastructure and deploys the application
# Usage: .\deploy.ps1

param(
    [string]$AwsAccessKeyId = "",
    [string]$AwsSecretAccessKey = "",
    [string]$AwsSessionToken = "",
    [string]$Action = "deploy"
)

# Color output for better readability
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
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Yellow
}

# Set script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

# Step 0: Check Prerequisites
Write-Header "CHECKING PREREQUISITES"

$Prerequisites = @("terraform", "ansible", "kubectl", "helm")
$MissingTools = @()

foreach ($tool in $Prerequisites) {
    if (Get-Command $tool -ErrorAction SilentlyContinue) {
        Write-Success "$tool is installed"
    } else {
        Write-Error "$tool is NOT installed"
        $MissingTools += $tool
    }
}

if ($MissingTools.Count -gt 0) {
    Write-Error "Missing tools: $($MissingTools -join ', ')"
    Write-Host ""
    Write-Host "Please install the required tools:"
    Write-Host "  - Terraform: https://www.terraform.io/downloads"
    Write-Host "  - Ansible: https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html"
    Write-Host "  - kubectl: https://kubernetes.io/docs/tasks/tools/"
    Write-Host "  - Helm: https://helm.sh/docs/intro/install/"
    Write-Host ""
    exit 1
}

# Step 1: Configure AWS Credentials
Write-Header "STEP 1: AWS CREDENTIALS CONFIGURATION"

# Check if aws_credentials file exists
$AwsCredsFile = Join-Path $ScriptDir "aws_credentials"

if (-not (Test-Path $AwsCredsFile)) {
    Write-Info "aws_credentials file not found at $AwsCredsFile"
    Write-Info "Creating template file..."
    
    $template = @"
[default]
aws_access_key_id=YOUR_ACCESS_KEY_ID
aws_secret_access_key=YOUR_SECRET_ACCESS_KEY
aws_session_token=YOUR_SESSION_TOKEN
"@
    
    $template | Out-File -FilePath $AwsCredsFile -Encoding UTF8
    Write-Info "Template created at: $AwsCredsFile"
    Write-Error "Please edit aws_credentials with your AWS credentials"
    exit 1
}

# Parse aws_credentials file
$AwsConfig = @{}
Get-Content $AwsCredsFile | ForEach-Object {
    if ($_ -match "aws_access_key_id=(.+)") {
        $AwsAccessKeyId = $matches[1].Trim()
    }
    if ($_ -match "aws_secret_access_key=(.+)") {
        $AwsSecretAccessKey = $matches[1].Trim()
    }
    if ($_ -match "aws_session_token=(.+)") {
        $AwsSessionToken = $matches[1].Trim()
    }
}

# Validate credentials are not placeholders
if ($AwsAccessKeyId -like "*YOUR*" -or $AwsSecretAccessKey -like "*YOUR*") {
    Write-Error "AWS credentials not configured. Please edit aws_credentials file"
    Write-Host ""
    Write-Host "Edit this file: $AwsCredsFile"
    Write-Host "Add your AWS credentials (Access Key ID, Secret Access Key, and optionally Session Token)"
    Write-Host ""
    exit 1
}

Write-Success "AWS credentials configured"
$env:AWS_ACCESS_KEY_ID = $AwsAccessKeyId
$env:AWS_SECRET_ACCESS_KEY = $AwsSecretAccessKey
if ($AwsSessionToken) {
    $env:AWS_SESSION_TOKEN = $AwsSessionToken
}

# Step 2: Initialize and Apply Terraform
Write-Header "STEP 2: PROVISIONING INFRASTRUCTURE WITH TERRAFORM"

$TerraformDir = Join-Path $ScriptDir "terraform"
Push-Location $TerraformDir

Write-Info "Initializing Terraform..."
terraform init
if ($LASTEXITCODE -ne 0) {
    Write-Error "Terraform init failed"
    exit 1
}

Write-Info "Applying Terraform configuration..."
terraform apply -auto-approve
if ($LASTEXITCODE -ne 0) {
    Write-Error "Terraform apply failed"
    exit 1
}

Write-Success "Infrastructure provisioned successfully"

# Get outputs
Write-Info "Retrieving infrastructure details..."
$ALB_DNS = terraform output -raw alb_dns_name 2>$null
$MASTER_IP = terraform output -json instance_ips | ConvertFrom-Json | Select-Object -Index 0
$WORKER1_IP = terraform output -json instance_ips | ConvertFrom-Json | Select-Object -Index 1
$WORKER2_IP = terraform output -json instance_ips | ConvertFrom-Json | Select-Object -Index 2
$MASTER_PRIVATE_IP = terraform output -raw master_private_ip 2>$null
$SSH_KEY = terraform output -raw ssh_private_key 2>$null

# Save SSH key to file
$KeyFile = Join-Path $ScriptDir "generated_key.pem"
$SSH_KEY | Out-File -FilePath $KeyFile -Encoding UTF8 -Force
(Get-Item $KeyFile).Attributes = 'Archive'
Write-Success "SSH key saved to: $KeyFile"

Pop-Location

# Step 3: Wait for instances to be ready
Write-Header "STEP 3: WAITING FOR EC2 INSTANCES TO BE READY"

Write-Info "Waiting for instances to accept SSH connections..."
$MaxAttempts = 30
$Attempt = 0

foreach ($ip in @($MASTER_IP, $WORKER1_IP, $WORKER2_IP)) {
    $Ready = $false
    $Attempt = 0
    
    while (-not $Ready -and $Attempt -lt $MaxAttempts) {
        try {
            $test = Test-NetConnection -ComputerName $ip -Port 22 -WarningAction SilentlyContinue
            if ($test.TcpTestSucceeded) {
                Write-Success "Instance $ip is ready for SSH"
                $Ready = $true
            } else {
                $Attempt++
                Write-Info "Waiting for $ip... (attempt $Attempt/$MaxAttempts)"
                Start-Sleep -Seconds 10
            }
        } catch {
            $Attempt++
            Write-Info "Waiting for $ip... (attempt $Attempt/$MaxAttempts)"
            Start-Sleep -Seconds 10
        }
    }
    
    if (-not $Ready) {
        Write-Error "Instance $ip did not become ready in time"
        exit 1
    }
}

# Step 4: Create Ansible Inventory
Write-Header "STEP 4: CONFIGURING ANSIBLE"

$InventoryFile = Join-Path $ScriptDir "ansible\inventory.ini"
$InventoryContent = @"
[master]
$MASTER_IP ansible_user=ubuntu ansible_ssh_private_key_file=$KeyFile ansible_ssh_common_args='-o StrictHostKeyChecking=no -o ConnectTimeout=10'

[worker]
$WORKER1_IP ansible_user=ubuntu ansible_ssh_private_key_file=$KeyFile ansible_ssh_common_args='-o StrictHostKeyChecking=no -o ConnectTimeout=10'
$WORKER2_IP ansible_user=ubuntu ansible_ssh_private_key_file=$KeyFile ansible_ssh_common_args='-o StrictHostKeyChecking=no -o ConnectTimeout=10'

[all:vars]
ansible_python_interpreter=/usr/bin/python3
"@

$InventoryContent | Out-File -FilePath $InventoryFile -Encoding UTF8 -Force
Write-Success "Ansible inventory created"

# Step 5: Run Ansible Playbook
Write-Header "STEP 5: CONFIGURING KUBERNETES AND NFS WITH ANSIBLE"

$AnsibleDir = Join-Path $ScriptDir "ansible"
Push-Location $AnsibleDir

Write-Info "Running Ansible playbook (this may take 5-10 minutes)..."
$env:ANSIBLE_HOST_KEY_CHECKING = 'False'
ansible-playbook playbook.yml -i inventory.ini

if ($LASTEXITCODE -ne 0) {
    Write-Error "Ansible playbook failed"
    Write-Host ""
    Write-Host "You can manually retry with:"
    Write-Host "  cd $AnsibleDir"
    Write-Host "  ansible-playbook playbook.yml -i inventory.ini -vvv"
    exit 1
}

Write-Success "Kubernetes cluster and NFS configured successfully"
Pop-Location

# Step 6: Fetch and Configure kubeconfig
Write-Header "STEP 6: PREPARING KUBERNETES ACCESS"

$KubeconfigPath = Join-Path $ScriptDir "kubeconfig"
Write-Info "Fetching kubeconfig from master node..."

# Try to copy kubeconfig from master
$TempKubeconfig = Join-Path $env:TEMP "kubeconfig_temp"

try {
    # Using SSH to get kubeconfig
    $SSHCommand = @"
`$ProgressPreference = 'SilentlyContinue'
ssh -i '$KeyFile' -o StrictHostKeyChecking=no -o ConnectTimeout=10 ubuntu@$MASTER_IP "cat /home/ubuntu/.kube/config" | Out-File -FilePath '$TempKubeconfig' -Encoding UTF8
"@
    
    Invoke-Expression $SSHCommand
    
    if (Test-Path $TempKubeconfig) {
        # Update server address in kubeconfig to use public IP
        $KubeContent = Get-Content $TempKubeconfig -Raw
        $KubeContent = $KubeContent -replace "server: https://[^:]+:6443", "server: https://$MASTER_IP`:6443"
        $KubeContent | Out-File -FilePath $KubeconfigPath -Encoding UTF8 -Force
        Remove-Item $TempKubeconfig -Force
        Write-Success "kubeconfig saved to: $KubeconfigPath"
    } else {
        Write-Error "Failed to fetch kubeconfig"
        exit 1
    }
} catch {
    Write-Error "Error fetching kubeconfig: $_"
    exit 1
}

# Step 7: Deploy with Helm
Write-Header "STEP 7: DEPLOYING APPLICATION WITH HELM"

$HelmDir = Join-Path $ScriptDir "helm\car-lot"
$env:KUBECONFIG = $KubeconfigPath

Write-Info "Adding application to Kubernetes cluster..."
Write-Info "Using Docker image: azexkush/car-lot-manager:latest"
Write-Info "Using NFS server: $MASTER_PRIVATE_IP"

Push-Location $ScriptDir

helm upgrade --install car-lot-manager ./helm/car-lot `
    --set nfs.server=$MASTER_PRIVATE_IP `
    --kubeconfig=$KubeconfigPath `
    --wait --timeout 15m

if ($LASTEXITCODE -ne 0) {
    Write-Error "Helm deployment failed"
    Write-Host ""
    Write-Host "You can retry with:"
    Write-Host "  helm upgrade --install car-lot-manager ./helm/car-lot --set nfs.server=$MASTER_PRIVATE_IP --kubeconfig=$KubeconfigPath"
    exit 1
}

Write-Success "Application deployed successfully with Helm"
Pop-Location

# Step 8: Wait for deployment to be ready
Write-Header "STEP 8: WAITING FOR APPLICATION TO BE READY"

Write-Info "Waiting for application pods to be ready (this may take a few minutes)..."
$MaxWait = 0
$MaxWaitTime = 300  # 5 minutes

while ($MaxWait -lt $MaxWaitTime) {
    try {
        $readyReplicas = kubectl get deployment car-lot-manager -o jsonpath='{.status.readyReplicas}' --kubeconfig=$KubeconfigPath 2>$null
        $desiredReplicas = kubectl get deployment car-lot-manager -o jsonpath='{.spec.replicas}' --kubeconfig=$KubeconfigPath 2>$null
        
        if ($readyReplicas -eq $desiredReplicas -and $desiredReplicas -ne "") {
            Write-Success "All application pods are ready"
            break
        } else {
            Write-Info "Ready replicas: $readyReplicas/$desiredReplicas. Waiting..."
            Start-Sleep -Seconds 15
            $MaxWait += 15
        }
    } catch {
        Write-Info "Checking pod status... (attempt $($MaxWait/15))"
        Start-Sleep -Seconds 15
        $MaxWait += 15
    }
}

# Final Summary
Write-Header "DEPLOYMENT COMPLETE! SUCCESS!"

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "YOUR APPLICATION IS NOW LIVE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

Write-Host "APPLICATION ACCESS:" -ForegroundColor Cyan
Write-Host "  URL: http://$ALB_DNS" -ForegroundColor Green
Write-Host ""

Write-Host "INFRASTRUCTURE DETAILS:" -ForegroundColor Cyan
Write-Host "  Master Node (public IP):      $MASTER_IP" -ForegroundColor White
Write-Host "  Master Node (private IP):     $MASTER_PRIVATE_IP" -ForegroundColor White
Write-Host "  Worker 1 (public IP):         $WORKER1_IP" -ForegroundColor White
Write-Host "  Worker 2 (public IP):         $WORKER2_IP" -ForegroundColor White
Write-Host "  Load Balancer DNS:            $ALB_DNS" -ForegroundColor White
Write-Host ""

Write-Host "FILES:" -ForegroundColor Cyan
Write-Host "  SSH Key:                      $KeyFile" -ForegroundColor White
Write-Host "  Kubeconfig:                   $KubeconfigPath" -ForegroundColor White
Write-Host "  Ansible Inventory:            $InventoryFile" -ForegroundColor White
Write-Host ""

Write-Host "USEFUL COMMANDS:" -ForegroundColor Cyan
Write-Host "  Check pod status:             kubectl get pods --kubeconfig=$KubeconfigPath" -ForegroundColor White
Write-Host "  View pod logs:                kubectl logs -l app=car-lot-manager --kubeconfig=$KubeconfigPath" -ForegroundColor White
Write-Host "  SSH to master:                ssh -i '$KeyFile' ubuntu@$MASTER_IP" -ForegroundColor White
Write-Host "  Access dashboard:             http://$ALB_DNS" -ForegroundColor White
Write-Host ""

Write-Host "NEXT STEPS:" -ForegroundColor Cyan
Write-Host "  1. Open browser: http://$ALB_DNS" -ForegroundColor White
Write-Host "  2. You should see the Car Lot Manager application" -ForegroundColor White
Write-Host "  3. Sample cars are already loaded (Toyota, Honda, Ford)" -ForegroundColor White
Write-Host "  4. Try adding, selling, or removing cars" -ForegroundColor White
Write-Host ""

Write-Host "TO CLEAN UP INFRASTRUCTURE:" -ForegroundColor Cyan
Write-Host "  cd terraform" -ForegroundColor White
Write-Host "  terraform destroy -auto-approve" -ForegroundColor White
Write-Host ""

Write-Host "========================================" -ForegroundColor Green
Write-Host "Happy testing! Contact admin for support." -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
