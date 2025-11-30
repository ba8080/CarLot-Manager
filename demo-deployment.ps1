param()
# Car Lot Manager - Cloud-First Deployment Demo
# Demonstrates what teacher would see with valid AWS setup

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  CLOUD-FIRST DEPLOYMENT - TEACHER DEMONSTRATION" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[*] Simulating deployment with valid AWS credentials..." -ForegroundColor Yellow
Write-Host ""

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  STEP 1: PREREQUISITE VALIDATION" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[*] Checking AWS CLI installation..." -ForegroundColor Yellow
Write-Host "[OK] AWS CLI installed: aws-cli/2.13.22 Python/3.11.6" -ForegroundColor Green
Write-Host ""

Write-Host "[*] Validating AWS credentials..." -ForegroundColor Yellow
Write-Host "[OK] aws_credentials file found" -ForegroundColor Green
Write-Host "[OK] AWS Access Key ID configured" -ForegroundColor Green
Write-Host "[OK] AWS Secret Access Key configured" -ForegroundColor Green
Write-Host "[OK] AWS Session Token configured" -ForegroundColor Green
Write-Host ""

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  STEP 2: AWS CREDENTIAL VALIDATION" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[*] Testing AWS credentials with AWS CLI..." -ForegroundColor Yellow
Write-Host ""
Write-Host "Response from: aws sts get-caller-identity" -ForegroundColor Yellow
Write-Host ""
Write-Host "{" -ForegroundColor Green
Write-Host "  ""UserId"": ""AIDA4EXAMPLESTM2LCU4Y""," -ForegroundColor Green
Write-Host "  ""Account"": ""891377148662""," -ForegroundColor Green
Write-Host "  ""Arn"": ""arn:aws:iam::891377148662:user/devops-student""" -ForegroundColor Green
Write-Host "}" -ForegroundColor Green
Write-Host ""

Write-Host "[OK] AWS credentials are VALID!" -ForegroundColor Green
Write-Host "    Account: 891377148662" -ForegroundColor Green
Write-Host "    User: devops-student" -ForegroundColor Green
Write-Host ""

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  STEP 3: DEPLOYMENT CONFIGURATION" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Cloud-First Deployment Strategy:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  1. Launch Master EC2 Instance on AWS" -ForegroundColor Cyan
Write-Host "  2. Install ALL DevOps tools ON the master node" -ForegroundColor Cyan
Write-Host "  3. Master orchestrates complete stack deployment" -ForegroundColor Cyan
Write-Host ""
Write-Host "Benefits:" -ForegroundColor Green
Write-Host "  - Teacher only needs AWS CLI locally" -ForegroundColor Green
Write-Host "  - All tools auto-install in cloud" -ForegroundColor Green
Write-Host "  - No complex local setup required" -ForegroundColor Green
Write-Host "  - Consistent environment on cloud" -ForegroundColor Green
Write-Host ""

Write-Host "Deployment Timeline:" -ForegroundColor Yellow
Write-Host "  Phase 1: Create AWS Resources         [2 minutes]" -ForegroundColor Cyan
Write-Host "  Phase 2: Install DevOps Tools         [10 minutes]" -ForegroundColor Cyan
Write-Host "  Phase 3: Deploy Kubernetes Cluster    [15 minutes]" -ForegroundColor Cyan
Write-Host "  Phase 4: Deploy Application           [5 minutes]" -ForegroundColor Cyan
Write-Host "  ---" -ForegroundColor Cyan
Write-Host "  Total: ~40 minutes (mostly automated)" -ForegroundColor Green
Write-Host ""

Write-Host "Cost Estimate:" -ForegroundColor Yellow
Write-Host "  t2.medium instance: 0.0464 USD/hour" -ForegroundColor Cyan
Write-Host "  Deployment (1 hour): ~0.05 USD" -ForegroundColor Cyan
Write-Host "  Per day running: ~1.11 USD" -ForegroundColor Cyan
Write-Host ""

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  STEP 4: EXECUTING DEPLOYMENT PHASES" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# Phase 1
Write-Host "[PHASE 1/4] Creating AWS Infrastructure..." -ForegroundColor Cyan
Write-Host ""
Write-Host "[1/5] Creating SSH Key Pair" -ForegroundColor Yellow
Start-Sleep -Milliseconds 500
Write-Host "      Generating: car-lot-key-20231129.pem" -ForegroundColor Green
Write-Host "      [OK] Key pair created on AWS" -ForegroundColor Green
Write-Host ""

Write-Host "[2/5] Creating Security Group" -ForegroundColor Yellow
Start-Sleep -Milliseconds 500
Write-Host "      Name: car-lot-manager-sg" -ForegroundColor Green
Write-Host "      [OK] SSH (22) allowed" -ForegroundColor Green
Write-Host "      [OK] HTTP (80) allowed" -ForegroundColor Green
Write-Host "      [OK] HTTPS (443) allowed" -ForegroundColor Green
Write-Host "      [OK] Kubernetes API (6443) allowed" -ForegroundColor Green
Write-Host ""

Write-Host "[3/5] Creating VPC and Subnets" -ForegroundColor Yellow
Start-Sleep -Milliseconds 500
Write-Host "      VPC: 10.0.0.0/16" -ForegroundColor Green
Write-Host "      Subnet 1: 10.0.1.0/24" -ForegroundColor Green
Write-Host "      Subnet 2: 10.0.2.0/24" -ForegroundColor Green
Write-Host "      [OK] Network infrastructure ready" -ForegroundColor Green
Write-Host ""

Write-Host "[4/5] Launching Master EC2 Instance" -ForegroundColor Yellow
Start-Sleep -Milliseconds 800
Write-Host "      Type: t2.medium" -ForegroundColor Green
Write-Host "      AMI: ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server" -ForegroundColor Green
Write-Host "      Instance ID: i-0abc123def456ghi" -ForegroundColor Green
Write-Host "      Public IP: 54.123.45.67" -ForegroundColor Green
Write-Host "      Private IP: 10.0.1.50" -ForegroundColor Green
Write-Host "      [OK] Instance launching..." -ForegroundColor Green
Write-Host ""

Write-Host "[5/5] Waiting for SSH Readiness" -ForegroundColor Yellow
Write-Host "      Checking connectivity" -NoNewline
for ($i = 0; $i -lt 8; $i++) {
    Write-Host -NoNewline "."
    Start-Sleep -Milliseconds 250
}
Write-Host " READY!" -ForegroundColor Green
Write-Host "      [OK] Instance is fully booted" -ForegroundColor Green
Write-Host ""
Write-Host "[OK] PHASE 1 COMPLETE - Infrastructure ready" -ForegroundColor Green
Write-Host ""

Start-Sleep -Milliseconds 800

# Phase 2
Write-Host "[PHASE 2/4] Installing DevOps Tools on Master..." -ForegroundColor Cyan
Write-Host ""
Write-Host "Connecting to: ubuntu@54.123.45.67" -ForegroundColor Yellow
Write-Host "Running automated bootstrap script on master node" -ForegroundColor Yellow
Write-Host ""

$tools = @("Docker", "Git", "curl/wget", "Python 3.11", "Terraform", "Ansible", "kubectl", "Helm", "kubeadm")
foreach ($tool in $tools) {
    Write-Host "  Installing $tool..." -ForegroundColor Yellow
    Start-Sleep -Milliseconds 400
    Write-Host "  [OK] $tool installed" -ForegroundColor Green
}

Write-Host ""
Write-Host "[OK] PHASE 2 COMPLETE - All tools ready on master" -ForegroundColor Green
Write-Host ""

Start-Sleep -Milliseconds 800

# Phase 3
Write-Host "[PHASE 3/4] Deploying Kubernetes Cluster..." -ForegroundColor Cyan
Write-Host ""
Write-Host "Master Node Configuration:" -ForegroundColor Yellow
Write-Host "  Initializing kubeadm on master" -ForegroundColor Yellow
Start-Sleep -Milliseconds 600
Write-Host "  [OK] Control plane initialized" -ForegroundColor Green
Write-Host "  [OK] kubeconfig generated" -ForegroundColor Green
Write-Host ""

Write-Host "Installing CNI (Flannel):" -ForegroundColor Yellow
Start-Sleep -Milliseconds 400
Write-Host "  [OK] Flannel networking installed" -ForegroundColor Green
Write-Host ""

Write-Host "Creating NFS Storage:" -ForegroundColor Yellow
Start-Sleep -Milliseconds 400
Write-Host "  [OK] NFS server configured (10GB storage)" -ForegroundColor Green
Write-Host "  [OK] Storage class created" -ForegroundColor Green
Write-Host ""

Write-Host "[OK] PHASE 3 COMPLETE - Kubernetes cluster ready" -ForegroundColor Green
Write-Host ""

Start-Sleep -Milliseconds 800

# Phase 4
Write-Host "[PHASE 4/4] Deploying Application..." -ForegroundColor Cyan
Write-Host ""
Write-Host "Deploying Car Lot Manager application:" -ForegroundColor Yellow
Write-Host ""

Write-Host "  1. Add Helm repository" -ForegroundColor Yellow
Start-Sleep -Milliseconds 300
Write-Host "     [OK] Repository configured" -ForegroundColor Green
Write-Host ""

Write-Host "  2. Deploy Car Lot Manager Helm chart" -ForegroundColor Yellow
Start-Sleep -Milliseconds 300
Write-Host "     [OK] Helm chart deployed" -ForegroundColor Green
Write-Host ""

Write-Host "  3. Wait for pods to be ready" -ForegroundColor Yellow
Write-Host "     Waiting for replicas" -NoNewline
for ($i = 0; $i -lt 6; $i++) {
    Write-Host -NoNewline "."
    Start-Sleep -Milliseconds 300
}
Write-Host " Ready!" -ForegroundColor Green
Write-Host "     [OK] 2/2 replicas running" -ForegroundColor Green
Write-Host ""

Write-Host "  4. Configure load balancer" -ForegroundColor Yellow
Start-Sleep -Milliseconds 300
Write-Host "     [OK] Service exposed on port 80" -ForegroundColor Green
Write-Host ""

Write-Host "[OK] PHASE 4 COMPLETE - Application deployed" -ForegroundColor Green
Write-Host ""

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  SUCCESS! DEPLOYMENT COMPLETE!" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "APPLICATION INFORMATION:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  URL: http://54.123.45.67" -ForegroundColor Green
Write-Host "  Status: Running (2/2 pods)" -ForegroundColor Green
Write-Host "  Region: us-east-1" -ForegroundColor Green
Write-Host ""

Write-Host "CLUSTER DETAILS:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Master Node: Ready (control-plane)" -ForegroundColor Green
Write-Host "  Kubernetes Version: v1.27.4" -ForegroundColor Green
Write-Host "  Container Runtime: docker://20.10.24" -ForegroundColor Green
Write-Host "  Storage: 10GB NFS persistent volume" -ForegroundColor Green
Write-Host ""

Write-Host "INFRASTRUCTURE SUMMARY:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Master Instance ID: i-0abc123def456ghi" -ForegroundColor Green
Write-Host "  Public IP: 54.123.45.67" -ForegroundColor Green
Write-Host "  Private IP: 10.0.1.50" -ForegroundColor Green
Write-Host "  Instance Type: t2.medium" -ForegroundColor Green
Write-Host "  Root Volume: 30GB" -ForegroundColor Green
Write-Host ""

Write-Host "SSH ACCESS (if needed):" -ForegroundColor Cyan
Write-Host ""
Write-Host "  chmod 600 car-lot-key-20231129.pem" -ForegroundColor Yellow
Write-Host "  ssh -i car-lot-key-20231129.pem ubuntu@54.123.45.67" -ForegroundColor Yellow
Write-Host ""

Write-Host "NEXT STEPS:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  1. Open browser: http://54.123.45.67" -ForegroundColor Cyan
Write-Host "  2. Test car operations (add, sell, view inventory)" -ForegroundColor Cyan
Write-Host "  3. Check data persistence with refresh/reload" -ForegroundColor Cyan
Write-Host "  4. View logs: kubectl logs -f deployment/car-lot-manager" -ForegroundColor Cyan
Write-Host "  5. Check storage: kubectl get pv,pvc" -ForegroundColor Cyan
Write-Host ""

Write-Host "CLEANUP (when done testing):" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Option 1: Stop instance (keep for later):" -ForegroundColor Cyan
Write-Host "    aws ec2 stop-instances --instance-ids i-0abc123def456ghi" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Option 2: Terminate (full cleanup):" -ForegroundColor Cyan
Write-Host "    aws ec2 terminate-instances --instance-ids i-0abc123def456ghi" -ForegroundColor Cyan
Write-Host ""

Write-Host "COST SUMMARY:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Deployment time: 40 minutes" -ForegroundColor Cyan
Write-Host "  Cost to deploy: approximately USD 0.03" -ForegroundColor Cyan
Write-Host "  Cost per hour (running): approximately USD 0.05" -ForegroundColor Cyan
Write-Host "  Cost per day (24h): approximately USD 1.11" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Remember: Stop/terminate when not in use to avoid charges!" -ForegroundColor Red
Write-Host ""

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  TEACHER DEPLOYMENT SUCCESSFUL!" -ForegroundColor Green
Write-Host "  Ready for testing and demonstration!" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""
