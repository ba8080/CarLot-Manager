#!/bin/bash

# CarLot Manager Deployment Script

set -e

APP_NAME="carlot-manager"
AWS_REGION="us-east-1"
ECR_REPO_NAME="$APP_NAME"
GITHUB_REPO="https://github.com/ba8080/CarLot-Manager.git"

echo "Starting deployment process..."

# Get AWS Account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_URI="$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO_NAME:latest"

# 1. Deploy CloudFormation infrastructure
echo "Deploying CloudFormation infrastructure..."
aws cloudformation deploy \
  --template-file aws-cloudformation/template.yaml \
  --stack-name $APP_NAME-infrastructure \
  --parameter-overrides file://aws-cloudformation/parameters.json \
  --capabilities CAPABILITY_IAM \
  --region $AWS_REGION

# 2. Build Docker image with GitHub repo
echo "Building Docker image..."
docker build -f docker/Dockerfile --build-arg GITHUB_REPO=$GITHUB_REPO -t $APP_NAME .

# 3. Get ECR login token
echo "Logging into ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# 4. Tag and push image to ECR
echo "Pushing image to ECR..."
docker tag $APP_NAME:latest $ECR_URI
docker push $ECR_URI

# 5. Update Dockerrun.aws.json with correct ECR URI
echo "Updating Dockerrun.aws.json..."
sed -i.bak "s/ACCOUNT_ID/$ACCOUNT_ID/g" Dockerrun.aws.json
sed -i.bak "s/REGION/$AWS_REGION/g" Dockerrun.aws.json

# 6. Create application version and deploy to Beanstalk
echo "Creating application version..."
zip -r app-$(date +%Y%m%d-%H%M%S).zip Dockerrun.aws.json aws-beanstalk/

# 7. Deploy to Elastic Beanstalk
echo "Deploying to Elastic Beanstalk..."
eb init $APP_NAME --region $AWS_REGION --platform docker
eb create $APP_NAME-prod --instance-types t3.small --min-instances 2 --max-instances 4

echo "Deployment completed successfully!"
echo "ECR Repository: $ECR_URI"
echo "Application URL: $(aws cloudformation describe-stacks --stack-name $APP_NAME-infrastructure --query 'Stacks[0].Outputs[?OutputKey==`ApplicationURL`].OutputValue' --output text)"