# Pipeline Deployment Checklist

## ✅ Pre-Deployment Checklist

### 1. GitHub Secrets Configuration
Ensure these secrets are set in your GitHub repository (Settings → Secrets and variables → Actions):

- [ ] `AWS_ACCESS_KEY_ID` - Your AWS access key
- [ ] `AWS_SECRET_ACCESS_KEY` - Your AWS secret key
- [ ] `AWS_SESSION_TOKEN` - Your AWS session token (if using temporary credentials)
- [ ] `DOCKERHUB_USERNAME` - Docker Hub username (should be: `azexkush`)
- [ ] `DOCKERHUB_TOKEN` - Docker Hub access token

### 2. Repository Configuration
- [ ] Repository is public or you have proper access
- [ ] Main branch is named `main` (not `master`)
- [ ] GitHub Actions are enabled for the repository

### 3. Local Validation (Optional but Recommended)
Run these commands before pushing:

```bash
# Validate Terraform
cd terraform
terraform fmt
terraform validate -backend=false
cd ..

# Validate Helm
helm lint helm/car-lot

# Validate Python
python3 -m py_compile app/app.py
python3 -m py_compile ansible/generate_inventory.py

# Run tests
cd tests
python3 -m unittest test_functions.py
cd ..
```

## 🚀 Deployment Steps

### Step 1: Push to Main Branch
```bash
git add .
git commit -m "Deploy CarLot Manager"
git push origin main
```

### Step 2: Monitor Pipeline
1. Go to GitHub repository → Actions tab
2. Click on the latest workflow run
3. Monitor each job:
   - ✅ Build & Push Docker (~3-5 min)
   - ✅ Terraform Provisioning (~5-7 min)
   - ✅ Ansible Cluster Setup (~8-12 min)
   - ✅ Helm Deployment (~2-3 min)

### Step 3: Get Application URL
After successful deployment:
1. Check the "Helm Deployment" job logs
2. Look for the "Display Application URL" step
3. Copy the ALB URL (format: `http://carlot-alb-xxxxx.us-east-1.elb.amazonaws.com`)
4. Wait 2-3 minutes for ALB health checks to pass
5. Access the application

## 🔍 Troubleshooting

### Pipeline Fails at Docker Build
**Issue**: Docker login fails or image push fails
**Solution**: 
- Verify `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` secrets
- Ensure Docker Hub account has push permissions
- Check if repository `azexkush/carlot-app` exists

### Pipeline Fails at Terraform
**Issue**: AWS credentials invalid or insufficient permissions
**Solution**:
- Verify AWS secrets are correct
- Ensure AWS account has permissions for:
  - EC2 (create instances, security groups)
  - VPC (create VPC, subnets, internet gateway)
  - ELB (create load balancers, target groups)
  - IAM (if needed for roles)

### Pipeline Fails at Ansible
**Issue**: SSH connection timeout or Ansible playbook errors
**Solution**:
- Check EC2 instances are running (AWS Console)
- Verify security groups allow SSH (port 22)
- Wait longer for instances to initialize
- Check Ansible playbook syntax

### Pipeline Fails at Helm
**Issue**: Kubernetes cluster not ready or Helm deployment fails
**Solution**:
- Verify Kubernetes cluster is initialized
- Check kubeconfig is properly fetched
- Ensure pods can pull Docker image
- Verify NodePort 30080 is accessible

### Application Not Accessible
**Issue**: ALB URL returns 503 or timeout
**Solution**:
- Wait 2-3 minutes for ALB health checks
- Check target group health in AWS Console
- Verify pods are running: `kubectl get pods`
- Check service: `kubectl get svc`
- Verify NodePort 30080 is open in security groups

## 🧹 Cleanup

To destroy all resources and avoid AWS charges:

```bash
cd terraform
terraform destroy -auto-approve
```

Or manually delete:
1. EC2 instances
2. Load balancer
3. Target groups
4. VPC and subnets
5. Security groups
6. Key pairs

## 📊 Expected Timeline

| Stage | Duration | Status Check |
|-------|----------|--------------|
| Docker Build | 3-5 min | Image pushed to Docker Hub |
| Terraform | 5-7 min | EC2 instances running |
| Ansible | 8-12 min | K8s cluster initialized |
| Helm | 2-3 min | Pods running |
| ALB Health | 2-3 min | Targets healthy |
| **Total** | **20-30 min** | Application accessible |

## ✨ Success Indicators

- ✅ All GitHub Actions jobs show green checkmarks
- ✅ ALB URL is displayed in Helm deployment logs
- ✅ Application loads in browser
- ✅ Can add/remove/sell cars in the UI
- ✅ Data persists across page refreshes

## 🔐 Security Notes

- SSH keys are generated automatically by Terraform
- Keys are stored as GitHub Actions artifacts (deleted after 1 day)
- Security groups allow SSH from anywhere (0.0.0.0/0) - restrict in production
- Application uses HTTP (not HTTPS) - add SSL/TLS for production

## 📝 Common Git Issues

### Merge Conflicts
```bash
git pull origin main --rebase
# Resolve conflicts
git add .
git rebase --continue
git push origin main
```

### Force Push (Use with Caution)
```bash
git push origin main --force
```

### Check Remote Status
```bash
git remote -v
git status
git log --oneline -5
```

## 🎯 Quick Commands

```bash
# Check pipeline status
gh run list --limit 5

# View latest run logs
gh run view --log

# Trigger manual workflow
gh workflow run cicd.yml

# Check AWS resources
aws ec2 describe-instances --filters "Name=tag:Name,Values=k8s-node-*"
aws elbv2 describe-load-balancers --names carlot-alb-*
```
