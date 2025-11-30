# Car Lot Manager - Deployment Status & Next Steps

## Current Status

✅ **Terraform Deployment: COMPLETE**
- 3 EC2 instances created (t2.medium each)
- Application Load Balancer created
- VPC with public subnets configured
- Security groups properly set up
- SSH key generated and saved as `generated_key.pem`

## Infrastructure Details

**Master Node:**
- IP: `54.152.227.8`
- Role: Kubernetes control-plane + NFS server
- Status: Running and SSH-ready

**Worker Nodes:**
- Worker 1 IP: `52.202.128.111`
- Worker 2 IP: `54.221.27.136`
- Status: Running and SSH-ready

**Load Balancer:**
- DNS: `carlot-alb-729782486.us-east-1.elb.amazonaws.com`
- Target Group Port: 30080 (NodePort)
- Current Status: Targets UNHEALTHY (waiting for application pods)

## Why Targets Are Unhealthy

The Load Balancer targets show as "Unhealthy" because:
1. Kubernetes cluster is not yet fully initialized
2. Application pods have not been deployed yet
3. Service is not listening on port 30080 yet

Once you complete the final deployment steps below, targets will become HEALTHY.

## Final Deployment Steps

### Step 1: Connect to Master Node

```bash
ssh -i generated_key.pem ubuntu@54.152.227.8
```

### Step 2: Wait for Kubernetes to Initialize

```bash
# Check if nodes are ready
kubectl get nodes

# Wait for nodes to show "Ready" status (2-3 minutes)
# Expected output:
# NAME            STATUS   ROLES           AGE   VERSION
# 54.152.227.8    Ready    control-plane   3m    v1.27.4
# 52.202.128.111  Ready    <none>          2m    v1.27.4
# 54.221.27.136   Ready    <none>          2m    v1.27.4
```

### Step 3: Create Namespace & Deploy Application

```bash
# Create namespace
kubectl create namespace car-lot

# Clone the project (if not already there)
cd $HOME
git clone https://github.com/ba8080/CarLot-Manager.git
cd CarLot-Manager

# Deploy with Helm
helm upgrade --install car-lot ./helm/car-lot \
  -n car-lot \
  --create-namespace \
  --set image.repository=ba8080/car-lot-manager \
  --set image.tag=latest \
  --set replicaCount=2
```

### Step 4: Verify Deployment

```bash
# Check pod status
kubectl get pods -n car-lot

# Expected output after 2-3 minutes:
# NAME                    READY   STATUS    RESTARTS   AGE
# car-lot-manager-pod1    1/1     Running   0          2m
# car-lot-manager-pod2    1/1     Running   0          2m

# Check service
kubectl get svc -n car-lot

# Should show NodePort service on port 30080
```

### Step 5: Verify Load Balancer Health

```bash
# Check Load Balancer target health
aws elb describe-instance-health --load-balancer-name carlot-alb --region us-east-1

# Or use AWS Console:
# EC2 → Target Groups → carlot-tg
# Status should change from "Unhealthy" to "Healthy"
```

## Access the Application

Once pods are running and Load Balancer targets are HEALTHY:

**URL:** `http://54.152.227.8`

or use the Load Balancer DNS:

**URL:** `http://carlot-alb-729782486.us-east-1.elb.amazonaws.com`

## Troubleshooting

### Pods not starting?

```bash
# Check logs
kubectl logs -f deployment/car-lot -n car-lot

# Describe pod for details
kubectl describe pod <pod-name> -n car-lot

# Check events
kubectl get events -n car-lot
```

### Load Balancer still unhealthy?

```bash
# Verify service is running
kubectl get svc -n car-lot

# Check if NodePort is accessible
curl -v http://54.152.227.8:30080

# Check security groups allow traffic on port 30080
aws ec2 describe-security-groups --region us-east-1
```

### NFS storage not working?

```bash
# Check storage class
kubectl get storageclass

# Check PVC status
kubectl get pvc -n car-lot

# Check NFS server on master
sudo exportfs -v
sudo showmount -e localhost
```

## Cleanup (When Done)

To destroy all infrastructure and stop AWS charges:

```powershell
# On your local machine
cd C:\Users\user\Desktop\CarLot-Manager
cd terraform
terraform destroy -auto-approve
```

## Architecture Summary

```
┌─────────────────────────────────────────────┐
│         AWS Account (us-east-1)             │
├─────────────────────────────────────────────┤
│                                             │
│  ┌──────────────────────────────────────┐  │
│  │   Application Load Balancer (ALB)    │  │
│  │   Port: 80 → NodePort: 30080        │  │
│  └─────┬────────────────────────────────┘  │
│        │                                    │
│  ┌─────▼──────┬──────────┬──────────────┐  │
│  │   Master   │ Worker 1 │ Worker 2    │  │
│  │ 54.152...  │ 52.202.. │ 54.221...   │  │
│  │            │          │             │  │
│  │ Control    │ Pod      │ Pod         │  │
│  │ Plane      │ Replica1 │ Replica2    │  │
│  │ NFS Server │          │             │  │
│  └────────────┴──────────┴──────────────┘  │
│                                             │
│  ┌──────────────────────────────────────┐  │
│  │   VPC (10.0.0.0/16)                  │  │
│  │   Public Subnets + Security Groups   │  │
│  └──────────────────────────────────────┘  │
│                                             │
└─────────────────────────────────────────────┘
```

## Project Requirements Status

✅ **1. Application Enhancement**
- File-based data persistence
- Docker image pushed to Docker Hub
- Initial dummy data included

✅ **2. Infrastructure as Code**
- Terraform provisions 3 EC2s, Load Balancer, VPC

✅ **3. Configuration Management**
- Ansible ready to configure Kubernetes
- NFS server configured on master

✅ **4. Kubernetes Deployment**
- Helm charts prepared for deployment
- 2 replicas for high availability

⏳ **5. CI/CD Pipeline**
- GitHub Actions workflow ready
- Tests passing locally

✅ **6. Networking Configuration**
- Load Balancer routes port 80 to NodePort 30080
- End-to-end connectivity configured

## Next: GitHub Actions CI/CD

Once manual deployment is verified working, set up GitHub Actions:

1. Push to GitHub repository
2. Add AWS credentials to GitHub Secrets:
   - AWS_ACCESS_KEY_ID
   - AWS_SECRET_ACCESS_KEY
   - AWS_SESSION_TOKEN

3. GitHub Actions will automatically:
   - Run tests
   - Build Docker image
   - Push to Docker Hub
   - Run Terraform
   - Run Ansible
   - Deploy with Helm

## Support

For issues or questions, check:
- Application logs: `kubectl logs -f deployment/car-lot -n car-lot`
- System logs: SSH to master and check `/var/log/` directories
- Terraform state: `terraform show` in terraform directory
