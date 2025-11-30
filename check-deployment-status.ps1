# Check Deployment Status Script
# Run this to monitor your Kubernetes deployment progress

param(
    [string]$MasterIP = "54.152.227.8",
    [string]$KeyFile = "generated_key.pem"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CAR LOT MANAGER - DEPLOYMENT STATUS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if SSH key exists
if (!(Test-Path $KeyFile)) {
    Write-Host "ERROR: SSH key not found: $KeyFile" -ForegroundColor Red
    exit 1
}

Write-Host "Master IP: $MasterIP" -ForegroundColor Yellow
Write-Host "SSH Key: $KeyFile" -ForegroundColor Yellow
Write-Host ""

# 1. Check if master is reachable
Write-Host "[1/4] Checking if master node is reachable..." -ForegroundColor Cyan
$pingTest = ssh -i "$KeyFile" -o StrictHostKeyChecking=no -o ConnectTimeout=5 "ubuntu@$MasterIP" "echo 'OK'" 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Master node is reachable" -ForegroundColor Green
} else {
    Write-Host "✗ Cannot reach master node. Still starting up?" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# 2. Check Kubernetes nodes
Write-Host "[2/4] Checking Kubernetes nodes..." -ForegroundColor Cyan
$nodesCheck = ssh -i "$KeyFile" -o StrictHostKeyChecking=no "ubuntu@$MasterIP" "kubectl get nodes 2>/dev/null" 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host $nodesCheck -ForegroundColor Green
} else {
    Write-Host "⏳ Kubernetes not ready yet. Still initializing..." -ForegroundColor Yellow
}

Write-Host ""

# 3. Check pods
Write-Host "[3/4] Checking application pods..." -ForegroundColor Cyan
$podsCheck = ssh -i "$KeyFile" -o StrictHostKeyChecking=no "ubuntu@$MasterIP" "kubectl get pods -n car-lot 2>/dev/null" 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host $podsCheck -ForegroundColor Green
} else {
    Write-Host "⏳ Pods not created yet" -ForegroundColor Yellow
}

Write-Host ""

# 4. Check bootstrap progress
Write-Host "[4/4] Checking bootstrap script progress..." -ForegroundColor Cyan
$processCheck = ssh -i "$KeyFile" -o StrictHostKeyChecking=no "ubuntu@$MasterIP" "ps aux | grep -E 'kubernetes-bootstrap|kubeadm|docker|helm' | grep -v grep | wc -l" 2>&1
if ($LASTEXITCODE -eq 0) {
    $processCount = [int]$processCheck
    if ($processCount -gt 0) {
        Write-Host "⏳ Bootstrap is still running ($processCount processes active)" -ForegroundColor Green
        ssh -i "$KeyFile" -o StrictHostKeyChecking=no "ubuntu@$MasterIP" "ps aux | grep -E 'kubeadm|docker|helm' | grep -v grep | head -3"
    } else {
        Write-Host "✓ Bootstrap script completed!" -ForegroundColor Green
    }
} else {
    Write-Host "⏳ Cannot check processes" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "TIMELINE:" -ForegroundColor Yellow
Write-Host "  0-2 min:  System startup" -ForegroundColor Gray
Write-Host "  2-4 min:  Docker and Kubernetes tools installing" -ForegroundColor Gray
Write-Host "  4-7 min:  Kubernetes master initializing" -ForegroundColor Gray
Write-Host "  7-9 min:  Helm chart deploying" -ForegroundColor Gray
Write-Host "  9+ min:  Pods starting and application ready" -ForegroundColor Gray
Write-Host ""
Write-Host "ONCE PODS ARE 'Running':" -ForegroundColor Cyan
Write-Host "  Open browser: http://$MasterIP" -ForegroundColor Green
Write-Host ""
Write-Host "Run this script again in 2 minutes to check progress" -ForegroundColor Yellow
