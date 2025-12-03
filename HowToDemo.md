# Car Lot Manager - AWS Deployment Demo Guide

## 🎯 **Demo Overview**
This guide shows how to deploy a Dockerized Streamlit web application to AWS with High Availability using Elastic Beanstalk and ECR.

---

## 📋 **Prerequisites**
- AWS Account with sandbox limitations (us-east-1 or us-west-2)
- Docker installed
- AWS CLI installed and configured
- EB CLI installed (`pip install awsebcli`)
- Git installed

---

## 🚀 **Step 1: Clone and Prepare the Project**

```bash
# Clone the repository
git clone https://github.com/ba8080/CarLot-Manager.git
cd CarLot-Manager

# Check the project structure
ls -la
```

**Expected files:**
- `website/app.py` - Streamlit web application
- `docker/Dockerfile` - Docker configuration
- `Dockerrun.aws.json` - Elastic Beanstalk Docker configuration

---

## 🐳 **Step 2: Test Docker Image Locally**

```bash
# Build the Docker image
docker build -t car-lot-manager -f docker/Dockerfile .

# Test locally (optional)
docker run -d -p 8501:8501 car-lot-manager

# Open browser to http://localhost:8501 to verify it works
# Stop the container: docker stop $(docker ps -q --filter ancestor=car-lot-manager)
```

---

## ☁️ **Step 3: Setup AWS ECR (Elastic Container Registry)**

```bash
# Create ECR repository
aws ecr create-repository --repository-name car-lot-manager --region us-east-1

# Get login token and authenticate Docker
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 332678858794.dkr.ecr.us-east-1.amazonaws.com

# Tag and push image to ECR
docker tag car-lot-manager:latest 332678858794.dkr.ecr.us-east-1.amazonaws.com/car-lot-manager:latest
docker push 332678858794.dkr.ecr.us-east-1.amazonaws.com/car-lot-manager:latest
```

**✅ Using AWS Account ID: 332678858794**

---

## 🔧 **Step 4: Update Dockerrun.aws.json**

Edit `Dockerrun.aws.json` to use your ECR image:

```json
{
  "AWSEBDockerrunVersion": "1",
  "Image": {
    "Name": "332678858794.dkr.ecr.us-east-1.amazonaws.com/car-lot-manager:latest",
    "Update": "true"
  },
  "Ports": [
    {
      "ContainerPort": "8501"
    }
  ]
}
```

---

## 🏗️ **Step 5: Create Clean Deployment Package**

```bash
# Create clean deployment directory
mkdir deploy
cp Dockerrun.aws.json deploy/
cd deploy

# Remove any .ebextensions or config files that might cause issues
# (These can cause WSGIPath errors for Docker deployments)
```

---

## 🚀 **Step 6: Deploy to Elastic Beanstalk**

```bash
# Initialize EB application
eb init clean-app --platform docker --region us-east-1

# Create environment with High Availability setup
eb create production-env \
  --elb-type application \
  --instance_type t2.micro \
  --scale 2 \
  --service-role LabRole \
  --instance_profile LabInstanceProfile \
  --keyname vockey
```

**Key Parameters:**
- `--scale 2`: Creates 2 instances for High Availability
- `--elb-type application`: Uses Application Load Balancer
- `--service-role LabRole`: Uses pre-created role (sandbox requirement)
- `--instance_profile LabInstanceProfile`: Uses pre-created instance profile

---

## ⏳ **Step 7: Wait for Deployment**

```bash
# Monitor deployment status
eb status

# Get the application URL
eb open
```

**Deployment typically takes 3-5 minutes**

---

## ✅ **Step 8: Verify Deployment**

1. **Access the Application:**
   - URL format: `http://production-env.eba-xxxxxx.us-east-1.elasticbeanstalk.com`
   - Should load the Car Lot Manager Streamlit interface

2. **Test Functionality:**
   - Add a new car to inventory
   - Edit car details
   - Mark a car as sold
   - View inventory and statistics

---

## 🏥 **Step 9: Demonstrate High Availability**

### Check Running Instances
```bash
# List EC2 instances
aws ec2 describe-instances --region us-east-1 \
  --query "Reservations[*].Instances[?State.Name=='running'].{InstanceId:InstanceId,AZ:Placement.AvailabilityZone,State:State.Name}" \
  --output table
```

### Test Failover
1. **Stop First Instance:**
   ```bash
   # Get instance ID from above command
   aws ec2 stop-instances --instance-ids i-xxxxxxxxx --region us-east-1
   ```

2. **Verify App Still Works:**
   - Refresh the application URL
   - Add/modify cars to verify functionality
   - App should continue working (traffic routed to remaining instance)

3. **Stop Second Instance:**
   ```bash
   # Start first instance, then stop second
   aws ec2 start-instances --instance-ids i-xxxxxxxxx --region us-east-1
   aws ec2 stop-instances --instance-ids i-yyyyyyyyy --region us-east-1
   ```

4. **Verify Again:**
   - App should still be functional
   - Demonstrates true High Availability

---

## 📊 **Step 10: Show Architecture Components**

### AWS Services Used:
1. **Elastic Container Registry (ECR)** - Stores Docker images
2. **Elastic Beanstalk** - Application deployment platform
3. **Application Load Balancer (ALB)** - Distributes traffic
4. **EC2 Auto Scaling** - Manages instance scaling
5. **EC2 Instances** - Hosts the application (t2.micro)
6. **Multiple Availability Zones** - Ensures high availability

### Architecture Diagram:
```
Internet → ALB → [AZ-1a: EC2] → Docker Container → Streamlit App
                ↘ [AZ-1b: EC2] → Docker Container → Streamlit App
```

---

## 🧹 **Step 11: Cleanup (After Demo)**

```bash
# Terminate environment
eb terminate production-env

# Delete application
aws elasticbeanstalk delete-application --application-name clean-app --region us-east-1

# Delete ECR repository
aws ecr delete-repository --repository-name car-lot-manager --force --region us-east-1
```

---

## 🚨 **Troubleshooting Common Issues**

### WSGIPath Error
- **Problem:** "Unknown or duplicate parameter: WSGIPath"
- **Solution:** Remove all `.ebextensions` folders and Python-specific configs

### Environment Health Issues
- **Problem:** Environment shows "Red" health status
- **Solution:** Check logs with `eb logs` and recreate environment

### Docker Image Issues
- **Problem:** Container fails to start
- **Solution:** Test locally first with `docker run`

### IAM Permission Issues
- **Problem:** Cannot create roles
- **Solution:** Use `--service-role LabRole --instance_profile LabInstanceProfile`

---

## 📝 **Demo Script for Presentation**

1. **Introduction (2 min):**
   - Explain the Car Lot Manager application
   - Show local Streamlit interface

2. **Docker Containerization (3 min):**
   - Show Dockerfile
   - Build and test locally

3. **AWS ECR Upload (2 min):**
   - Create repository
   - Push Docker image

4. **Elastic Beanstalk Deployment (5 min):**
   - Create high availability environment
   - Show deployment process

5. **Functionality Demo (3 min):**
   - Add/edit cars
   - Show real-time updates

6. **High Availability Test (5 min):**
   - Stop instances one by one
   - Demonstrate continued functionality

**Total Demo Time: ~20 minutes**

---

## 🔧 **AWS Sandbox Limitations Compliance**

✅ **Instance Types:** t2.micro only  
✅ **Region:** us-east-1  
✅ **Roles:** LabRole and LabInstanceProfile  
✅ **Instance Limit:** 2 instances (2 vCPUs total)  
✅ **Load Balancer:** Application Load Balancer  
✅ **Storage:** Under 35GB limit  

---

## 🎓 **Learning Outcomes Demonstrated**

- Containerization with Docker
- AWS ECR for image storage
- High Availability architecture design
- Load balancing and auto-scaling
- Infrastructure as Code principles
- Cloud deployment best practices
- Failover testing and validation

---

**🎉 End of Demo - Questions & Discussion**
