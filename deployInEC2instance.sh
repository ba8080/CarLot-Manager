#!/bin/bash

set -e

echo "🚀 Installing Docker..."
sudo apt-get update -y
sudo apt-get install -y docker.io
sudo systemctl enable docker
sudo systemctl start docker

echo "📦 Installing AWS CLI..."
sudo apt-get install -y unzip curl
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -o awscliv2.zip
sudo ./aws/install

echo "🔐 Setting AWS credentials..."
mkdir -p ~/.aws

cat > ~/.aws/credentials <<EOF
[default]
aws_access_key_id=x
aws_secret_access_key=x
aws_session_token=x

echo "🔐 Logging in to ECR..."
aws ecr get-login-password --region us-east-1 | \
docker login --username AWS --password-stdin 332678858794.dkr.ecr.us-east-1.amazonaws.com

echo "📥 Pulling and running the Docker image..."
docker pull 332678858794.dkr.ecr.us-east-1.amazonaws.com/carlotmanger:latest

docker run -d -p 80:8501 --name carlot-app \
  332678858794.dkr.ecr.us-east-1.amazonaws.com/carlotmanger:latest

echo "✅ App deployed! Access it at http://<your-EC2-public-ip>/"
