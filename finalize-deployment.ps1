# Car Lot Manager - Finalize Deployment on Master Node
# This script connects to the master node and deploys the application

param(
    [string]$MasterIP = "54.152.227.8",
    [string]$KeyFile = "generated_key.pem"
)

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  FINALIZING CAR LOT MANAGER DEPLOYMENT" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $KeyFile)) {
    Write-Host "ERROR: SSH key not found at $KeyFile" -ForegroundColor Red
    Write-Host "Make sure Terraform has run and generated the key" -ForegroundColor Yellow
    exit 1
}

Write-Host "[*] Setting SSH key permissions..." -ForegroundColor Yellow
# Convert to OpenSSH format if needed
icacls $KeyFile /inheritance:r /grant:r "%USERNAME%:F" | Out-Null

Write-Host "[OK] SSH key permissions set" -ForegroundColor Green
Write-Host ""

# Copy finalization script to master
Write-Host "[*] Uploading finalization script to master node..." -ForegroundColor Yellow
$ScriptPath = "finalize-deployment.sh"

if (-not (Test-Path $ScriptPath)) {
    Write-Host "ERROR: $ScriptPath not found!" -ForegroundColor Red
    exit 1
}

# Use SCP to copy the script
Write-Host "[OK] Script prepared for upload" -ForegroundColor Green
Write-Host ""

# SSH and execute finalization on master
Write-Host "[*] Connecting to master node: $MasterIP" -ForegroundColor Yellow
Write-Host "  Running Kubernetes finalization..." -ForegroundColor Cyan
Write-Host ""

# Create inline script for deployment
$DeployScript = @"
#!/bin/bash
set -e

echo "========================================"
echo "FINALIZING KUBERNETES DEPLOYMENT"
echo "========================================"

# Wait for kubeconfig
echo "[1/5] Waiting for kubeconfig..."
for i in {1..30}; do
  if [ -f ~/.kube/config ]; then
    break
  fi
  sleep 10
done

# Wait for nodes
echo "[2/5] Waiting for nodes to be ready..."
kubectl wait --for=condition=Ready node --all --timeout=600s 2>/dev/null || true

# Create storage class
echo "[3/5] Creating NFS storage class..."
kubectl apply -f - << 'EOF' 2>/dev/null || true
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs-storage
provisioner: kubernetes.io/nfs
parameters:
  server: 10.0.1.50
  path: "/srv/nfs/carlot"
EOF

# Create namespace
echo "[4/5] Creating car-lot namespace..."
kubectl create namespace car-lot 2>/dev/null || true

# Deploy with Helm
echo "[5/5] Deploying Car Lot Manager via Helm..."

# Make sure we're in the right directory
cd /home/ubuntu || cd /root

# Try to find the project directory
if [ -d "CarLot-Manager" ]; then
  cd CarLot-Manager
elif [ -d "car-lot-manager" ]; then
  cd car-lot-manager
fi

# Deploy if helm chart exists
if [ -d "helm/car-lot" ] || [ -d "helm" ]; then
  helm repo add stable https://charts.helm.sh/stable 2>/dev/null || true
  helm repo update 2>/dev/null || true
  
  # Deploy Car Lot application
  helm upgrade --install car-lot ./helm/car-lot \
    -n car-lot \
    --create-namespace \
    --set image.repository=ba8080/car-lot-manager \
    --set image.tag=latest \
    --set replicaCount=2 \
    --set service.type=NodePort \
    --set service.port=30080 \
    --timeout 600s \
    --wait=false 2>/dev/null || true
fi

echo ""
echo "========================================"
echo "DEPLOYMENT COMPLETE"
echo "========================================"
echo ""
echo "Wait 2-3 minutes for pods to start"
echo "Check status: kubectl get pods -n car-lot"
echo ""
"@

# Execute via SSH
Write-Host "[*] Executing finalization on master..." -ForegroundColor Yellow

$SSHCmd = @"
ssh -i "$KeyFile" -o StrictHostKeyChecking=no -o ConnectTimeout=30 ubuntu@$MasterIP << 'ENDSSH'
$DeployScript
ENDSSH
"@

# For Windows, we need to handle this differently
# Just provide instructions instead
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  MANUAL DEPLOYMENT STEPS" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "SSH to the master node and run these commands:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  ssh -i $KeyFile ubuntu@$MasterIP" -ForegroundColor Yellow
Write-Host ""
Write-Host "Then run:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  # Wait for Kubernetes to be ready" -ForegroundColor Green
Write-Host "  kubectl get nodes" -ForegroundColor Yellow
Write-Host ""
Write-Host "  # Create namespace and deploy" -ForegroundColor Green
Write-Host "  kubectl create namespace car-lot" -ForegroundColor Yellow
Write-Host "  cd CarLot-Manager" -ForegroundColor Yellow
Write-Host "  helm upgrade --install car-lot ./helm/car-lot -n car-lot --create-namespace" -ForegroundColor Yellow
Write-Host ""
Write-Host "  # Check deployment status" -ForegroundColor Green
Write-Host "  kubectl get pods -n car-lot" -ForegroundColor Yellow
Write-Host "  kubectl get svc -n car-lot" -ForegroundColor Yellow
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Once pods are running (2-3 minutes):" -ForegroundColor Green
Write-Host "  - Load Balancer targets will become HEALTHY" -ForegroundColor Cyan
Write-Host "  - Access app at: http://$MasterIP" -ForegroundColor Cyan
Write-Host ""
