# DEPLOYMENT COMMANDS - Copy and Paste

## Your Current Infrastructure

```
Master Node: 54.152.227.8
Worker 1:    52.202.128.111
Worker 2:    54.221.27.136
SSH Key:     generated_key.pem
```

## Step-by-Step Commands

### STEP 1: Connect to Master Node

```bash
ssh -i generated_key.pem ubuntu@54.152.227.8
```

**You should now be logged into the master node.**

---

### STEP 2: Wait for Kubernetes Nodes to Be Ready

```bash
# Check node status
kubectl get nodes

# OR watch it become ready (stop with Ctrl+C when all show "Ready")
kubectl get nodes --watch
```

Expected output:
```
NAME            STATUS   ROLES           AGE   VERSION
54.152.227.8    Ready    control-plane   3m    v1.27.4
52.202.128.111  Ready    <none>          2m    v1.27.4
54.221.27.136   Ready    <none>          2m    v1.27.4
```

**Wait until all nodes show "Ready" status** (usually 2-5 minutes)

---

### STEP 3: Create Namespace

```bash
kubectl create namespace car-lot
```

---

### STEP 4: Navigate to Project Directory

```bash
# If project is already on master
cd CarLot-Manager

# OR if you need to clone it
cd ~
git clone https://github.com/ba8080/CarLot-Manager.git
cd CarLot-Manager
```

---

### STEP 5: Deploy Application with Helm

```bash
helm upgrade --install car-lot ./helm/car-lot \
  -n car-lot \
  --create-namespace \
  --set image.repository=ba8080/car-lot-manager \
  --set image.tag=latest \
  --set replicaCount=2 \
  --set service.type=NodePort \
  --set service.port=30080
```

---

### STEP 6: Watch Pods Start

```bash
# Watch pods become "Running"
kubectl get pods -n car-lot --watch

# OR check once
kubectl get pods -n car-lot
```

Expected output after 2-3 minutes:
```
NAME                    READY   STATUS    RESTARTS   AGE
car-lot-manager-xxxxx   1/1     Running   0          2m
car-lot-manager-yyyyy   1/1     Running   0          2m
```

**Stop watching when both show "Running"** (Press Ctrl+C)

---

### STEP 7: Verify Service is Running

```bash
# Check the service
kubectl get svc -n car-lot

# Test locally on master
curl http://localhost:30080
```

---

### STEP 8: Check Load Balancer Health (on your local machine, not SSH)

```bash
# In PowerShell on your machine
aws elb describe-instance-health --load-balancer-name carlot-alb --region us-east-1
```

Wait for all targets to show "InService" status.

---

## Access Your Application

Once everything is running:

**Option 1: Direct to Master**
```
http://54.152.227.8
```

**Option 2: Through Load Balancer**
```
http://carlot-alb-729782486.us-east-1.elb.amazonaws.com
```

---

## Useful Commands for Debugging

```bash
# View application logs
kubectl logs -f deployment/car-lot -n car-lot

# Describe a pod (for error details)
kubectl describe pod <pod-name> -n car-lot

# Check events in namespace
kubectl get events -n car-lot --sort-by='.lastTimestamp'

# Check persistent volumes
kubectl get pv,pvc -n car-lot

# Scale replicas if needed
kubectl scale deployment car-lot --replicas=3 -n car-lot

# Restart deployment
kubectl rollout restart deployment/car-lot -n car-lot
```

---

## If Pods Won't Start

```bash
# 1. Check pod logs
kubectl logs car-lot-manager-xxxxx -n car-lot

# 2. Describe pod for events
kubectl describe pod car-lot-manager-xxxxx -n car-lot

# 3. Check image is available
kubectl get nodes -o wide

# 4. If Docker image can't be pulled
# Make sure the image exists:
docker pull ba8080/car-lot-manager:latest
```

---

## Complete One-Liner (if you're comfortable with bash)

```bash
ssh -i generated_key.pem ubuntu@54.152.227.8 << 'EOF'
kubectl wait --for=condition=Ready node --all --timeout=600s
kubectl create namespace car-lot || true
cd CarLot-Manager
helm upgrade --install car-lot ./helm/car-lot -n car-lot --create-namespace
kubectl rollout status deployment/car-lot -n car-lot
echo "Deployment complete! Access at http://54.152.227.8"
EOF
```

---

## Cleanup (When Done Testing)

### Stop Instances (Keep for later)
```powershell
aws ec2 stop-instances --instance-ids i-0c7e8e9a35c5b203e i-04f22fac427b62dc7 i-0ec9ae90fad09cfec --region us-east-1
```

### Delete Everything
```powershell
cd C:\Users\user\Desktop\CarLot-Manager\terraform
terraform destroy -auto-approve
```

---

## Expected Results

✅ **Kubernetes Cluster:** 3 nodes ready  
✅ **Application Pods:** 2 replicas running  
✅ **Service:** Listening on port 30080  
✅ **Load Balancer:** Targets healthy  
✅ **Application:** Accessible at `http://54.152.227.8`  

---

That's it! Your Car Lot Manager is now running in production on AWS! 🚀
