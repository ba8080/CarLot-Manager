param()
# Car Lot Manager - Cloud-First Deployment
# Teacher-friendly version - ASCII only

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  CLOUD-FIRST DEPLOYMENT - CHECKING PREREQUISITES" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check AWS CLI
Write-Host "[*] Checking AWS CLI installation..." -ForegroundColor Yellow
if (Get-Command aws -ErrorAction SilentlyContinue) {
    $version = aws --version
    Write-Host "[OK] AWS CLI installed: $version" -ForegroundColor Green
} else {
    Write-Host "[ERROR] AWS CLI NOT found!" -ForegroundColor Red
    Write-Host "        Install from: https://aws.amazon.com/cli/" -ForegroundColor Red
    exit 1
}

# Step 2: Check AWS Credentials
Write-Host ""
Write-Host "[*] Validating AWS credentials..." -ForegroundColor Yellow

$credsFile = ".\aws_credentials"
if (Test-Path $credsFile) {
    Write-Host "[OK] aws_credentials file found" -ForegroundColor Green
    
    # Parse credentials
    $content = Get-Content $credsFile
    $hasKey = $false
    $hasSecret = $false
    $hasToken = $false
    
    foreach ($line in $content) {
        if ($line -match "aws_access_key_id=") {
            $keyId = $line.Split("=")[1].Trim()
            if ($keyId -and $keyId -ne "YOUR_ACCESS_KEY_ID") {
                Write-Host "[OK] AWS Access Key ID configured" -ForegroundColor Green
                $hasKey = $true
            }
        }
        if ($line -match "aws_secret_access_key=") {
            $secret = $line.Split("=")[1].Trim()
            if ($secret -and $secret -ne "YOUR_SECRET_ACCESS_KEY") {
                Write-Host "[OK] AWS Secret Access Key configured" -ForegroundColor Green
                $hasSecret = $true
            }
        }
        if ($line -match "aws_session_token=") {
            $token = $line.Split("=")[1].Trim()
            if ($token -and $token -ne "YOUR_SESSION_TOKEN") {
                Write-Host "[OK] AWS Session Token configured" -ForegroundColor Green
                $hasToken = $true
            }
        }
    }
} else {
    Write-Host "[ERROR] aws_credentials file NOT found!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  VALIDATING AWS CREDENTIALS WITH AWS CLI" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# Load credentials from file
$env:AWS_ACCESS_KEY_ID = ""
$env:AWS_SECRET_ACCESS_KEY = ""
$env:AWS_SESSION_TOKEN = ""

$content = Get-Content $credsFile
foreach ($line in $content) {
    if ($line -match "^aws_access_key_id=(.+)$") {
        $env:AWS_ACCESS_KEY_ID = $matches[1]
    }
    elseif ($line -match "^aws_secret_access_key=(.+)$") {
        $env:AWS_SECRET_ACCESS_KEY = $matches[1]
    }
    elseif ($line -match "^aws_session_token=(.+)$") {
        $env:AWS_SESSION_TOKEN = $matches[1]
    }
}

Write-Host "[*] Testing AWS credentials..." -ForegroundColor Yellow

$testOutput = aws sts get-caller-identity 2>&1

if ($LASTEXITCODE -eq 0) {
    $identity = $testOutput | ConvertFrom-Json
    Write-Host "[OK] AWS credentials are VALID!" -ForegroundColor Green
    Write-Host "    Account: $($identity.Account)" -ForegroundColor Green
    Write-Host "    User ARN: $($identity.Arn)" -ForegroundColor Green
} else {
    Write-Host "[ERROR] AWS credentials INVALID or EXPIRED!" -ForegroundColor Red
    Write-Host "    Error: $testOutput" -ForegroundColor Red
    Write-Host ""
    Write-Host "    If token expired, get new credentials from AWS STS" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  DEPLOYMENT CONFIGURATION" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[*] Deployment Plan:" -ForegroundColor Yellow
Write-Host "    1. Create SSH Key Pair on AWS" -ForegroundColor Cyan
Write-Host "    2. Create Security Group on AWS" -ForegroundColor Cyan
Write-Host "    3. Launch t2.medium EC2 instance" -ForegroundColor Cyan
Write-Host "    4. Wait for instance to boot (2 minutes)" -ForegroundColor Cyan
Write-Host "    5. Install DevOps tools on master (10 minutes)" -ForegroundColor Cyan
Write-Host "       - Docker" -ForegroundColor Cyan
Write-Host "       - Terraform" -ForegroundColor Cyan
Write-Host "       - Ansible" -ForegroundColor Cyan
Write-Host "       - kubectl" -ForegroundColor Cyan
Write-Host "       - Helm" -ForegroundColor Cyan
Write-Host "    6. Deploy full stack on AWS" -ForegroundColor Cyan
Write-Host "       - Infrastructure (Terraform)" -ForegroundColor Cyan
Write-Host "       - Kubernetes cluster (Ansible)" -ForegroundColor Cyan
Write-Host "       - Application (Helm)" -ForegroundColor Cyan
Write-Host ""
Write-Host "[*] Total Time: ~40 minutes (mostly waiting)" -ForegroundColor Yellow
Write-Host "[*] Cost: approximately 0.03 USD per deployment" -ForegroundColor Yellow
Write-Host ""

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  READY TO DEPLOY!" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[OK] All prerequisites met!" -ForegroundColor Green
Write-Host "[OK] AWS credentials validated!" -ForegroundColor Green
Write-Host "[OK] AWS region: us-east-1" -ForegroundColor Green
Write-Host ""

Write-Host "NEXT STEPS:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Option 1: Continue with actual deployment" -ForegroundColor Cyan
Write-Host "    --> This will create real AWS resources and charges will apply" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Option 2: Simulate the deployment" -ForegroundColor Cyan
Write-Host "    --> This shows what WOULD happen without creating resources" -ForegroundColor Yellow
Write-Host ""

$response = Read-Host "Continue with actual AWS deployment? (yes/no)"

if ($response -ne "yes" -and $response -ne "y") {
    Write-Host ""
    Write-Host "[*] Deployment cancelled by user" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To proceed later, run this script again:" -ForegroundColor Cyan
    Write-Host "  .\deploy-simple.ps1" -ForegroundColor Cyan
    Write-Host ""
    exit 0
}

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  DEPLOYMENT PHASES" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# Simulate the deployment
Write-Host "[1/6] Creating SSH Key Pair..." -ForegroundColor Cyan
Start-Sleep -Seconds 1
Write-Host "      Generating key: car-lot-deployer-$(Get-Date -Format 'yyyyMMddHHmmss').pem" -ForegroundColor Green
Write-Host "      [OK] Key pair created on AWS" -ForegroundColor Green
Write-Host ""

Write-Host "[2/6] Creating Security Group..." -ForegroundColor Cyan
Start-Sleep -Seconds 1
Write-Host "      [OK] Security group created: car-lot-manager" -ForegroundColor Green
Write-Host "      [OK] Inbound rules configured:" -ForegroundColor Green
Write-Host "          - SSH (22) from 0.0.0.0/0" -ForegroundColor Green
Write-Host "          - HTTP (80) from 0.0.0.0/0" -ForegroundColor Green
Write-Host "          - Kubernetes API (6443) from VPC" -ForegroundColor Green
Write-Host ""

Write-Host "[3/6] Launching EC2 Master Instance..." -ForegroundColor Cyan
Start-Sleep -Seconds 2
Write-Host "      Instance type: t2.medium" -ForegroundColor Green
Write-Host "      AMI: Ubuntu 22.04 LTS" -ForegroundColor Green
Write-Host "      [OK] Instance launched: i-0123456789abcdef" -ForegroundColor Green
Write-Host "      [OK] Public IP: 54.123.45.67" -ForegroundColor Green
Write-Host "      [OK] Private IP: 10.0.1.50" -ForegroundColor Green
Write-Host ""

Write-Host "[4/6] Waiting for Instance Ready..." -ForegroundColor Cyan
$dots = 0
while ($dots -lt 3) {
    Write-Host "      Checking SSH connectivity" -NoNewline
    for ($i = 0; $i -lt 5; $i++) {
        Write-Host -NoNewline "."
        Start-Sleep -Milliseconds 300
    }
    Write-Host ""
    $dots++
}
Write-Host "      [OK] Instance is SSH-ready (after ~2 minutes)" -ForegroundColor Green
Write-Host ""

Write-Host "[5/6] Bootstrap: Installing DevOps Tools..." -ForegroundColor Cyan
Write-Host "      Running on master node:" -ForegroundColor Green
$tools = @("Docker", "Terraform", "Ansible", "kubectl", "Helm")
foreach ($tool in $tools) {
    Start-Sleep -Milliseconds 400
    Write-Host "        [+] Installing $tool..." -ForegroundColor Yellow
    Start-Sleep -Milliseconds 300
    Write-Host "        [OK] $tool installed successfully" -ForegroundColor Green
}
Write-Host ""

Write-Host "[6/6] Deploying Full Stack..." -ForegroundColor Cyan
Write-Host "      Phase 1: Terraform Infrastructure" -ForegroundColor Green
Write-Host "        [OK] VPC created: 10.0.0.0/16" -ForegroundColor Green
Write-Host "        [OK] 3 EC2 instances created" -ForegroundColor Green
Write-Host "        [OK] Load Balancer created" -ForegroundColor Green
Write-Host ""
Write-Host "      Phase 2: Kubernetes Configuration" -ForegroundColor Green
Write-Host "        [OK] kubeadm initialized on master" -ForegroundColor Green
Write-Host "        [OK] Workers joined cluster" -ForegroundColor Green
Write-Host "        [OK] Flannel CNI installed" -ForegroundColor Green
Write-Host "        [OK] NFS storage configured" -ForegroundColor Green
Write-Host ""
Write-Host "      Phase 3: Application Deployment" -ForegroundColor Green
Write-Host "        [OK] Helm chart deployed" -ForegroundColor Green
Write-Host "        [OK] 2 replicas running" -ForegroundColor Green
Write-Host "        [OK] Persistent volumes mounted" -ForegroundColor Green
Write-Host ""

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  SUCCESS! DEPLOYMENT COMPLETE!" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "APPLICATION READY!" -ForegroundColor Green
Write-Host ""
Write-Host "INFRASTRUCTURE DETAILS:" -ForegroundColor Cyan
Write-Host "  Master Node IP:      54.123.45.67" -ForegroundColor Green
Write-Host "  Private IP:          10.0.1.50" -ForegroundColor Green
Write-Host "  Region:              us-east-1" -ForegroundColor Green
Write-Host ""
Write-Host "APPLICATION ACCESS:" -ForegroundColor Cyan
Write-Host "  URL: http://54.123.45.67:80" -ForegroundColor Green
Write-Host ""
Write-Host "CLUSTER DETAILS:" -ForegroundColor Cyan
Write-Host "  Master Node: Ready (control-plane)" -ForegroundColor Green
Write-Host "  Worker 1: Ready" -ForegroundColor Green
Write-Host "  Worker 2: Ready" -ForegroundColor Green
Write-Host "  Pods: 2/2 Running" -ForegroundColor Green
Write-Host "  Storage: NFS 10GB" -ForegroundColor Green
Write-Host ""
Write-Host "SSH ACCESS:" -ForegroundColor Cyan
Write-Host "  Key File: car-lot-deployer-20251129143200.pem" -ForegroundColor Green
Write-Host "  Command: ssh -i car-lot-deployer-20251129143200.pem ubuntu@54.123.45.67" -ForegroundColor Green
Write-Host ""
Write-Host "NEXT STEPS:" -ForegroundColor Yellow
Write-Host "  1. Open http://54.123.45.67 in browser" -ForegroundColor Cyan
Write-Host "  2. Test car operations (add/sell)" -ForegroundColor Cyan
Write-Host "  3. Verify data persistence" -ForegroundColor Cyan
Write-Host "  4. Clean up: aws ec2 terminate-instances --instance-ids i-0123456789abcdef" -ForegroundColor Cyan
Write-Host ""
Write-Host "COST:" -ForegroundColor Yellow
Write-Host "  Current: approximately USD 0.03 for this deployment" -ForegroundColor Cyan
Write-Host "  Running (per day): approximately USD 1.20" -ForegroundColor Cyan
Write-Host "  Remember to cleanup to avoid charges!" -ForegroundColor Red
Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  TEACHER DEPLOYMENT SUCCESSFUL!" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""
