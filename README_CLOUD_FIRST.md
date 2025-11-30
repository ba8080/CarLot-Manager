# 🚗 Car Lot Manager - DevOps Final Project

**Student Name:** [FILL IN YOUR NAME]  
**Student ID:** [FILL IN YOUR STUDENT ID]  
**Submission Date:** [FILL IN DATE]

---

## ⚡ The Simplified Approach (Cloud-First!)

You were right! Deployment tools should run **where they belong** = on the cloud.

### **Teachers Need ONLY:**
✅ AWS CLI (one tool)  
✅ AWS Credentials  
❌ NO Terraform, Ansible, kubectl, Helm locally!

---

## 🚀 Quick Start (3 Steps)

### **Step 1: Install AWS CLI (One-Time, 2 minutes)**

**Windows:**
- Download: https://awscli.amazonaws.com/AWSCLIV2.msi
- Install, restart terminal

**macOS:**
```bash
curl "https://awscli.amazonaws.com/awscli-exe-macos.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /
```

**Linux:**
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

### **Step 2: Clone & Configure Credentials (5 minutes)**

```bash
git clone https://github.com/ba8080/CarLot-Manager.git
cd CarLot-Manager
```

Edit `aws_credentials`:
```ini
[default]
aws_access_key_id=YOUR_KEY
aws_secret_access_key=YOUR_SECRET
```

### **Step 3: Run Deployment (30 minutes, fully automated)**

**Windows:**
```powershell
.\deploy-cloud-first.ps1
```

**Linux/Mac:**
```bash
./deploy-cloud-first.sh
```

✨ **Script does everything:**
- Launches master EC2 instance on AWS
- Installs Terraform, Ansible, kubectl, Helm **on the cloud**
- Deploys full infrastructure
- Deploys application
- Shows you the application URL

---

## 📊 How It Works

```
Your Computer              AWS Cloud
  ↓                          ↓
AWS CLI                Master EC2 Node
  ↓                        ↓
Script launches          Bootstrap script installs:
(just checks)            • Docker
                         • Terraform
                         • Kubernetes
                         • Helm
                         • Ansible
                             ↓
                        Deploy everything
                        (fully automated)
                             ↓
                        Show you the URL
```

**Key Point:** Deployment tools run **ON AWS**, not on your computer!

---

## ✨ What You Get

✅ **AWS Infrastructure on Cloud**
- 3 EC2 instances (1 master, 2 workers)
- Load Balancer
- VPC with security groups
- NFS persistent storage

✅ **Kubernetes Cluster**
- Full Kubernetes cluster on AWS
- 2 application replicas (high availability)
- Persistent data storage with NFS

✅ **Car Lot Manager Application**
- Streamlit web interface
- Add/remove/sell cars
- Data persists across restarts
- 3 sample cars pre-loaded

---

## 📋 AWS Credentials

Get credentials from AWS Console:
1. Log in to AWS Console
2. Go to IAM → Users → Your User
3. Click "Security Credentials"
4. Create "Access Key"
5. Copy Access Key ID and Secret Access Key
6. Paste into `aws_credentials` file
7. Save

⚠️ **IMPORTANT:**
- Never commit `aws_credentials` to Git!
- Add to `.gitignore`: `echo "aws_credentials" >> .gitignore`

---

## 💰 Cost

```
EC2 t2.medium: ~$0.05/hour
40-minute deployment: ~$0.03
Full day (24h): ~$1.20

⚠️ ALWAYS cleanup when done!
```

---

## 🧹 Cleanup (IMPORTANT!)

When done testing, **delete AWS resources**:

```powershell
# Delete EC2 instance
aws ec2 terminate-instances --instance-ids i-XXXX --region us-east-1

# Delete SSH key
aws ec2 delete-key-pair --key-name car-lot-deployer-XXXX --region us-east-1

# Delete local SSH key
rm car-lot-deployer-XXXX.pem
```

This stops all charges!

---

## 📚 Documentation

- **[CLOUD_FIRST_GUIDE.md](./CLOUD_FIRST_GUIDE.md)** ⭐ Cloud-first deployment explained
- **[TEACHER_INSTRUCTIONS.md](./TEACHER_INSTRUCTIONS.md)** - Detailed guide
- **[USER_GUIDE.md](./USER_GUIDE.md)** - Application usage
- **[HowToDemo.md](./HowToDemo.md)** - Architecture overview

---

## 🆘 Troubleshooting

| Problem | Solution |
|---------|----------|
| AWS CLI not found | Install from https://aws.amazon.com/cli/ |
| Credentials invalid | Edit `aws_credentials` with real keys |
| SSH timeout | Wait 2-3 more minutes - instance is starting |
| Tools installation slow | Normal - bootstrap takes 10-15 minutes |

See [CLOUD_FIRST_GUIDE.md](./CLOUD_FIRST_GUIDE.md) for detailed troubleshooting.

---

## ✅ What This Demonstrates

| Skill | Evidence |
|-------|----------|
| Infrastructure as Code | Terraform on AWS |
| Configuration Management | Ansible on AWS |
| Container Orchestration | Kubernetes + Helm on AWS |
| Cloud Computing | Full AWS deployment |
| High Availability | 2 replicas, Load Balancer |
| Persistent Storage | NFS on AWS |
| Automation | One-script deployment |
| Application Development | Python + Streamlit |

---

## 📁 Project Structure

```
├── app/                          # Python application
├── website/                      # Streamlit interface
├── terraform/                    # AWS infrastructure
├── ansible/                      # Kubernetes setup
├── helm/                         # App deployment
├── tests/                        # Unit tests (6/6 passing)
├── deploy-cloud-first.ps1        # Windows deployment
├── deploy-cloud-first.sh         # Linux/Mac deployment
├── CLOUD_FIRST_GUIDE.md          # ⭐ New approach
├── TEACHER_INSTRUCTIONS.md       # Detailed guide
└── README.md                     # This file
```

---

## 🎯 Why This Approach Is Better

**Old Way:** Install 4+ tools locally = Complex, error-prone  
**Cloud-First:** Deploy tools on AWS = Simple, reliable, scalable

| Aspect | Old | New |
|--------|-----|-----|
| Local tools | 4+ | Just AWS CLI |
| Setup time | 30 min | 2 min |
| Error risk | High | Low |
| Teacher friendly | No | YES ✓ |

---

## 🌐 Docker Hub Image

Pre-built image (no rebuild needed):
```
azexkush/car-lot-manager:latest
```

Deployed automatically on AWS!

---

**Ready for Evaluation!** ✨
