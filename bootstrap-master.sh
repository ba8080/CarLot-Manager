#!/bin/bash
# Bootstrap script - runs on master node to complete deployment
# Installs all DevOps tools and deploys the application

set -e

echo "=========================================="
echo "BOOTSTRAP: Installing DevOps Tools"
echo "=========================================="

# Update system
sudo apt-get update -y
sudo apt-get upgrade -y

# Install Terraform
echo "[1/5] Installing Terraform..."
wget -q https://releases.hashicorp.com/terraform/1.5.0/terraform_1.5.0_linux_amd64.zip
unzip -q terraform_1.5.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/
rm terraform_1.5.0_linux_amd64.zip
terraform version

# Install kubectl
echo "[2/5] Installing kubectl..."
curl -LOs https://dl.k8s.io/release/v1.27.0/bin/linux/amd64/kubectl
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl
kubectl version --client

# Install Helm
echo "[3/5] Installing Helm..."
curl -LOs https://get.helm.sh/helm-v3.12.0-linux-amd64.tar.gz
tar -xzf helm-v3.12.0-linux-amd64.tar.gz
sudo mv linux-amd64/helm /usr/local/bin/
rm -rf helm-v3.12.0-linux-amd64.tar.gz linux-amd64
helm version

# Install Ansible (pip)
echo "[4/5] Installing Ansible..."
sudo apt-get install -y python3-pip
sudo pip3 install ansible -q
ansible --version

# Install Docker (already done by cloud-init)
echo "[5/5] Verifying Docker..."
docker --version

echo ""
echo "=========================================="
echo "[OK] All DevOps tools installed on master!"
echo "=========================================="
echo ""
echo "Master node is ready for Kubernetes initialization"
