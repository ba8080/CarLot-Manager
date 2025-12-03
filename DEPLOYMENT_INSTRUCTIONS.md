# Complete Deployment Instructions

## Prerequisites

- AWS Account with credentials configured
- Docker Hub account
- Terraform v1.5+
- Ansible v2.10+
- Docker
- AWS CLI
- kubectl (optional, for debugging)

## Option 1: GitHub Actions (Recommended)

### Setup GitHub Secrets

Configure these secrets in your GitHub repository (Settings → Secrets and variables → Actions):

1. `AWS_ACCESS_KEY_ID` - Your AWS access key
2. `AWS_SECRET_ACCESS_KEY` - Your AWS secret key
3. `AWS_SESSION_TOKEN` - Your AWS session token (if using temporary credentials)
4. `DOCKERHUB_USERNAME` - Your Docker Hub username (e.g., azexkush)
5. `DOCKERHUB_TOKEN` - Your Docker Hub access token

### Trigger Deployment

1. Go to **Actions** tab in GitHub
2. Select **Complete CI/CD Pipeline**
3. Click **Run workflow**
4. Select `main` branch
5. Click **Run workflow**

The pipeline will:
- Build and push Docker image
- Deploy AWS infrastructure with Terraform
- Configure Kubernetes cluster with Ansible
- Deploy the application
- Verify everything works
- Output the Load Balancer URL

### Get the URL

After successful deployment, check the workflow logs for:
```
🌐 Access your Car Lot Manager at:
    http://carlot-alb-XXXXXXXX.us-east-1.elb.amazonaws.com/
```

## Option 2: Local Deployment

### Step 1: Configure AWS Credentials

```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_SESSION_TOKEN="your-session-token"  # if using temporary credentials
```

### Step 2: Login to Docker Hub

```bash
docker login
# Enter your Docker Hub credentials
```

### Step 3: Run Deployment Script

```bash
chmod +x deploy-local.sh
./deploy-local.sh
```

The script will automatically:
1. Build and push Docker image
2. Deploy infrastructure with Terraform
3. Wait for instances to boot
4. Configure Kubernetes cluster with Ansible
5. Deploy the application
6. Verify everything works
7. Output the Load Balancer URL

## Manual Step-by-Step Deployment

### 1. Build and Push Docker Image

```bash
docker build -t azexkush/car-lot-manager:latest .
docker push azexkush/car-lot-manager:latest
```

### 2. Deploy Infrastructure

```bash
cd terraform
terraform init
terraform apply -auto-approve
```

Get outputs:
```bash
terraform output alb_dns_name
terraform output instance_ips
terraform output -raw ssh_private_key > ../generated_key.pem
chmod 400 ../generated_key.pem
```

### 3. Create Ansible Inventory

Replace IPs with your actual instance IPs:

```bash
cat > ansible/inventory.ini << 'EOF'
[master]
<MASTER_IP> ansible_user=ubuntu ansible_ssh_private_key_file=../generated_key.pem ansible_ssh_common_args='-o StrictHostKeyChecking=no'

[worker]
<WORKER1_IP> ansible_user=ubuntu ansible_ssh_private_key_file=../generated_key.pem ansible_ssh_common_args='-o StrictHostKeyChecking=no'
<WORKER2_IP> ansible_user=ubuntu ansible_ssh_private_key_file=../generated_key.pem ansible_ssh_common_args='-o StrictHostKeyChecking=no'

[all:vars]
ansible_python_interpreter=/usr/bin/python3
EOF
```

### 4. Run Ansible Playbook

```bash
cd ansible
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory.ini playbook.yml
cd ..
```

### 5. Deploy Application

```bash
# Copy deployment manifest
scp -i generated_key.pem -o StrictHostKeyChecking=no ./simple-deployment.yaml ubuntu@<MASTER_IP>:/tmp/

# Deploy
ssh -i generated_key.pem -o StrictHostKeyChecking=no ubuntu@<MASTER_IP> "
    kubectl wait --for=condition=Ready nodes --all --timeout=300s
    kubectl apply -f /tmp/simple-deployment.yaml
    kubectl rollout status deployment/car-lot-simple --timeout=300s
    kubectl get pods
    kubectl get svc
"
```

### 6. Test Application

Wait 2-3 minutes for Load Balancer to register targets, then:

```bash
curl http://<ALB_DNS>/health
curl http://<ALB_DNS>/
```

## Verification

### Check Kubernetes Cluster

```bash
ssh -i generated_key.pem ubuntu@<MASTER_IP>
kubectl get nodes
kubectl get pods
kubectl get svc
kubectl logs -l app=car-lot-simple
```

### Check NodePort Directly

```bash
ssh -i generated_key.pem ubuntu@<MASTER_IP>
curl http://localhost:30080/health
curl http://localhost:30080/
```

### Check Load Balancer

```bash
curl http://<ALB_DNS>/health
curl http://<ALB_DNS>/api/inventory
```

## Troubleshooting

### 504 Gateway Timeout

If you get 504 errors:

1. Check target health:
```bash
aws elbv2 describe-target-groups --query "TargetGroups[?contains(TargetGroupName, 'carlot-tg')]"
aws elbv2 describe-target-health --target-group-arn <TG_ARN>
```

2. Verify pods are running:
```bash
ssh -i generated_key.pem ubuntu@<MASTER_IP> "kubectl get pods"
```

3. Check pod logs:
```bash
ssh -i generated_key.pem ubuntu@<MASTER_IP> "kubectl logs -l app=car-lot-simple"
```

4. Test NodePort directly:
```bash
ssh -i generated_key.pem ubuntu@<MASTER_IP> "curl http://localhost:30080/health"
```

### Pods Not Starting

```bash
ssh -i generated_key.pem ubuntu@<MASTER_IP> "
    kubectl describe pods
    kubectl get events --sort-by='.lastTimestamp'
"
```

### Nodes Not Ready

```bash
ssh -i generated_key.pem ubuntu@<MASTER_IP> "
    kubectl get nodes
    kubectl describe nodes
    sudo systemctl status kubelet
"
```

## Cleanup

### Using Terraform

```bash
cd terraform
terraform destroy -auto-approve
```

### Manual Cleanup

1. Delete Kubernetes resources:
```bash
ssh -i generated_key.pem ubuntu@<MASTER_IP> "kubectl delete all --all"
```

2. Destroy infrastructure:
```bash
cd terraform
terraform destroy -auto-approve
```

## Application Features

Once deployed, you can:

- **View Inventory**: Navigate to `http://<ALB_DNS>/`
- **Add Cars**: Use the form on the main page
- **API Access**: `http://<ALB_DNS>/api/inventory`
- **Health Check**: `http://<ALB_DNS>/health`

## Architecture

- **3 EC2 Instances**: 1 Kubernetes master + 2 workers (t2.medium)
- **Application Load Balancer**: Routes traffic to NodePort 30080
- **Docker Image**: Flask application with health checks
- **Storage**: Local storage (can be upgraded to NFS)
- **Networking**: VPC with 2 public subnets across 2 AZs

## Security Notes

- SSH key is auto-generated by Terraform
- Security groups allow only necessary ports
- All instances in public subnets with public IPs
- Load Balancer accepts HTTP traffic on port 80

## Performance

- 2 replicas for high availability
- Health checks every 5 seconds
- Load balancer distributes traffic across all nodes
- Auto-restart on failure
