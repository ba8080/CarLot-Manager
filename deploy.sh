#!/bin/bash

# Car Lot Manager - Automated AWS Deployment Script
# AWS Account: 332678858794, Region: us-east-1

set -e  # Exit on any error

REGION="us-east-1"
REPO_NAME="car-lot-manager"

echo "🔧 AWS Credentials Setup"
echo "Please enter your AWS credentials:"

read -p "AWS Access Key ID: " AWS_ACCESS_KEY_ID
read -s -p "AWS Secret Access Key: " AWS_SECRET_ACCESS_KEY
echo
read -s -p "AWS Session Token: " AWS_SESSION_TOKEN
echo

# Configure AWS CLI
aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID"
aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY"
aws configure set aws_session_token "$AWS_SESSION_TOKEN"
aws configure set region $REGION
aws configure set output json

echo "✅ AWS credentials configured!"
echo "🧪 Testing connection..."
aws sts get-caller-identity

if [ $? -ne 0 ]; then
    echo "❌ AWS connection failed. Please check your credentials."
    exit 1
fi

# Get actual account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_URI="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

echo "🚀 Starting automated deployment for Car Lot Manager..."
echo "📋 Using Account ID: $ACCOUNT_ID"

# Step 3: Setup AWS ECR
echo "📦 Setting up ECR repository..."
aws ecr create-repository --repository-name $REPO_NAME --region $REGION || echo "Repository may already exist"

# Authenticate Docker with ECR
echo "🔐 Authenticating Docker with ECR..."
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_URI

# Build and push Docker image
echo "🐳 Building Docker image..."
docker build -t $REPO_NAME -f docker/Dockerfile .

echo "📤 Pushing image to ECR..."
docker tag $REPO_NAME:latest $ECR_URI/$REPO_NAME:latest
docker push $ECR_URI/$REPO_NAME:latest

# Step 4: Update Dockerrun.aws.json
echo "📝 Updating Dockerrun.aws.json..."
cat > Dockerrun.aws.json << EOF
{
  "AWSEBDockerrunVersion": "1",
  "Image": {
    "Name": "$ECR_URI/$REPO_NAME:latest",
    "Update": "true"
  },
  "Ports": [
    {
      "ContainerPort": "8501"
    }
  ]
}
EOF

# Step 5: Create deployment package
echo "📁 Creating deployment package..."
mkdir -p deploy
cp Dockerrun.aws.json deploy/
cd deploy

# Step 6: Deploy to Elastic Beanstalk
echo "🏗️ Initializing Elastic Beanstalk..."
eb init clean-app --platform docker --region $REGION

echo "🚀 Creating production environment..."
eb create production-env \
  --elb-type application \
  --instance_type t2.micro \
  --scale 2 \
  --service-role LabRole \
  --instance_profile LabInstanceProfile \
  --keyname vockey

# Step 7: Wait and get status
echo "⏳ Waiting for deployment to complete..."
eb status

# Get and display the application URL
echo "🌐 Getting application URL..."
APP_URL=$(eb status | grep "CNAME:" | awk '{print $2}')

echo "✅ Deployment completed successfully!"
echo ""
echo "🎯 APPLICATION URL FOR DEMO:"
echo "http://$APP_URL"
echo ""
echo "Copy this URL for your class demonstration!"
echo ""
echo "📊 To check running instances:"
echo "aws ec2 describe-instances --region $REGION --query \"Reservations[*].Instances[?State.Name=='running'].{InstanceId:InstanceId,AZ:Placement.AvailabilityZone,State:State.Name}\" --output table"