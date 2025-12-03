# Quick Start - Complete the Deployment

## TL;DR

1. **SSH to master:**
   ```
   ssh -i generated_key.pem ubuntu@54.152.227.8
   ```

2. **Wait for Kubernetes:**
   ```
   kubectl get nodes
   ```
   (Wait until all nodes show "Ready")

3. **Deploy application:**
   ```
   kubectl create namespace car-lot
   cd CarLot-Manager
   helm upgrade --install car-lot ./helm/car-lot -n car-lot --create-namespace
   ```

4. **Wait 2-3 minutes**

5. **Access app:**
   ```
   http://54.152.227.8
   ```

## Complete Commands (Copy-Paste)

```bash
# 1. Connect to master
ssh -i generated_key.pem ubuntu@54.152.227.8

# 2. Wait for Kubernetes to be ready (usually 2-3 minutes)
kubectl get nodes --watch

# (Press Ctrl+C when all nodes show "Ready")

# 3. Create namespace
kubectl create namespace car-lot

# 4. Deploy application
cd CarLot-Manager
helm upgrade --install car-lot ./helm/car-lot -n car-lot --create-namespace

# 5. Monitor deployment
kubectl get pods -n car-lot --watch

# (Wait until both pods show "Running")

# 6. Check service
kubectl get svc -n car-lot
```

## Verify Everything Works

```bash
# Check pods are running
kubectl get pods -n car-lot

# Output should look like:
# NAME                    READY   STATUS    RESTARTS
# car-lot-manager-xxxxx   1/1     Running   0
# car-lot-manager-yyyyy   1/1     Running   0

# Check service exists
kubectl get svc -n car-lot

# Test locally on master
curl http://localhost:30080

# Or from your machine
curl http://54.152.227.8:30080
```

## Access Application

- **Direct:** `http://54.152.227.8`
- **Via ALB DNS:** `http://carlot-alb-729782486.us-east-1.elb.amazonaws.com`

Wait for Load Balancer targets to show "Healthy" before accessing via ALB.

## Common Issues

**Pods stuck in Pending?**
```bash
kubectl describe pod <pod-name> -n car-lot
kubectl logs <pod-name> -n car-lot
```

**Load Balancer still unhealthy?**
```bash
# Check targets are registered
kubectl get svc -n car-lot

# Restart deployment if needed
kubectl rollout restart deployment/car-lot -n car-lot
```

**Kubernetes nodes not ready?**
```bash
# Check node logs
kubectl describe node <node-name>

# Ansible may still be configuring, wait 5-10 minutes
```

## Cleanup Everything

```powershell
# On local machine
cd C:\Users\user\Desktop\CarLot-Manager\terraform
terraform destroy -auto-approve
```

That's it! The infrastructure will be completely destroyed and AWS charges will stop.
