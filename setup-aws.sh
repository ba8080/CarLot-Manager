#!/bin/bash

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
aws configure set region us-east-1
aws configure set output json

echo "✅ AWS credentials configured!"
echo "🧪 Testing connection..."
aws sts get-caller-identity

if [ $? -eq 0 ]; then
    echo "✅ AWS connection successful! You can now run ./deploy.sh"
else
    echo "❌ AWS connection failed. Please check your credentials."
fi