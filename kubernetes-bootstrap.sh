#!/bin/bash
set -e

echo "========== KUBERNETES BOOTSTRAP STARTING =========="

# Wait for cloud-init to complete
echo "[1/12] Waiting for system initialization..."
cloud-init status --wait
sleep 10

# Disable swap
echo "[2/12] Disabling swap..."
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#/g' /etc/fstab || true

# Install Docker
echo "[3/12] Installing Docker..."
sudo apt-get update -qq
sudo apt-get install -y -qq docker.io > /dev/null 2>&1
sudo usermod -aG docker ubuntu

# Install Kubernetes tools
echo "[4/12] Installing Kubernetes tools..."
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg 2>/dev/null
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null
sudo apt-get update -qq
sudo apt-get install -y -qq kubelet kubeadm kubectl > /dev/null 2>&1
sudo apt-mark hold kubelet kubeadm kubectl > /dev/null 2>&1

# Pull Docker image
echo "[5/12] Pulling Docker image..."
sudo docker pull azexkush/car-lot-manager:latest > /dev/null 2>&1

# Setup NFS
echo "[6/12] Setting up NFS server..."
sudo apt-get install -y -qq nfs-kernel-server > /dev/null 2>&1
sudo mkdir -p /srv/nfs/carlot
sudo chmod 777 /srv/nfs/carlot
echo '/srv/nfs/carlot *(rw,sync,no_subtree_check,no_root_squash)' | sudo tee -a /etc/exports > /dev/null 2>&1
sudo exportfs -a
sudo systemctl restart nfs-kernel-server

# Initialize Kubernetes
echo "[7/12] Initializing Kubernetes (this takes 1-2 minutes)..."
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --ignore-preflight-errors=NumCPU > /dev/null 2>&1

# Setup kubeconfig
echo "[8/12] Setting up kubeconfig..."
mkdir -p /home/ubuntu/.kube
sudo cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
sudo chown ubuntu:ubuntu /home/ubuntu/.kube/config

# Install Flannel
echo "[9/12] Installing Flannel CNI..."
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml > /dev/null 2>&1

# Wait for node to be ready
echo "[10/12] Waiting for Kubernetes node to be ready..."
kubectl wait --for=condition=Ready node --all --timeout=300s 2>/dev/null || true

# Create namespace
echo "[11/12] Creating namespace and deploying application..."
kubectl create namespace car-lot || true

# Deploy Helm chart
helm install car-lot ./helm/car-lot -n car-lot --create-namespace   --set image.repository=azexkush/car-lot-manager   --set image.tag=latest   --set replicaCount=2   --wait > /dev/null 2>&1 || true

# Create service
kubectl expose deployment car-lot -n car-lot --type=NodePort --port=8501 --target-port=8501 --name=car-lot-service 2>/dev/null || true

echo "[12/12] Kubernetes bootstrap complete!"
echo ""
echo "========== DEPLOYMENT STATUS =========="
kubectl get nodes
echo ""
echo "Pods:"
kubectl get pods -n car-lot
echo ""
echo "Application will be accessible at: http://34.227.71.249"
echo "Check pod status with: kubectl get pods -n car-lot --watch"
