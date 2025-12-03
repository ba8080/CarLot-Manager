# Manual Deployment Steps - After Running `python deploy-cloud-first.py`

Your infrastructure is now provisioned on AWS! Now you need to manually complete the Kubernetes and application deployment on the master node.

## Prerequisites
- SSH key: `generated_key.pem` (in your project folder)
- Master IP: `54.152.227.8` (from the deployment output)

---

## STEP 1: SSH to Master Node

```bash
ssh -i generated_key.pem ubuntu@54.152.227.8
```

You should now be connected to the master node.

---

## STEP 2: Wait for System Startup (2-3 minutes)

The instance is starting up. Wait for Ubuntu to complete initialization:

```bash
# Check system status
sudo systemctl status cloud-final
```

Wait until you see "active (exited)" - this means cloud-init is done.

---

## STEP 3: Install Kubernetes Tools (Manually)

Since Ansible playbook needs to be run from local machine, we'll install tools directly on master:

```bash
# Disable swap
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Install Docker
sudo apt-get update
sudo apt-get install -y docker.io

# Install Kubernetes tools
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# Pull Docker image
sudo docker pull azexkush/car-lot-manager:latest
```

---

## STEP 4: Install NFS Server (On Master)

```bash
# Install NFS server
sudo apt-get install -y nfs-kernel-server

# Create NFS directory
sudo mkdir -p /srv/nfs/carlot
sudo chmod 777 /srv/nfs/carlot

# Configure NFS exports
echo '/srv/nfs/carlot *(rw,sync,no_subtree_check,no_root_squash)' | sudo tee -a /etc/exports

# Start NFS
sudo exportfs -a
sudo systemctl restart nfs-kernel-server
```

---

## STEP 5: Initialize Kubernetes Master

```bash
# Initialize kubeadm
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --ignore-preflight-errors=NumCPU

# Setup kubeconfig
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Install Flannel CNI
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

# Wait for nodes to be ready
kubectl get nodes --watch
```

**Stop watching when you see STATUS = "Ready" (Press Ctrl+C)**

---

## STEP 6: Get Worker Join Command

```bash
# Display the join command
kubeadm token create --print-join-command
```

Copy the output - you'll need this for worker nodes.

---

## STEP 7: Join Worker Nodes (From Local Machine)

Open a NEW terminal on your local machine and run for each worker:

```bash
# For Worker 1 (52.202.128.111)
ssh -i generated_key.pem ubuntu@52.202.128.111

# Then on worker 1:
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl docker.io
sudo docker pull azexkush/car-lot-manager:latest

# Run the join command from Step 6
sudo <paste-join-command-here>

# Exit and repeat for Worker 2 (54.221.27.136)
exit
```

---

## STEP 8: Verify All Nodes Are Ready (Back to Master)

```bash
# Back on master node
kubectl get nodes
```

All 3 nodes should show "Ready" status.

---

## STEP 9: Create Storage Class

```bash
kubectl apply -f - << 'EOF'
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs-storage
provisioner: kubernetes.io/nfs
parameters:
  server: 10.0.1.50
  path: "/srv/nfs/carlot"
EOF
```

---

## STEP 10: Deploy Application with Helm

```bash
# Create namespace
kubectl create namespace car-lot

# Deploy with Helm
helm install car-lot ./helm/car-lot \
  -n car-lot \
  --create-namespace \
  --set image.repository=azexkush/car-lot-manager \
  --set image.tag=latest \
  --set replicaCount=2

# Watch pods start
kubectl get pods -n car-lot --watch
```

Wait until both pods show "Running" status (2-3 minutes). Press Ctrl+C to stop watching.

---

## STEP 11: Create Service

```bash
# Create NodePort service
kubectl expose deployment car-lot -n car-lot \
  --type=NodePort \
  --port=8501 \
  --target-port=8501 \
  --name=car-lot-service
```

---

## STEP 12: Access Your Application

```bash
# Check service port
kubectl get svc -n car-lot

# Note the NodePort (usually 30xxx)
```

Now open your browser and go to:
```
http://54.152.227.8
```

Or with the specific port:
```
http://54.152.227.8:30080
```

---

## Troubleshooting

### Pods won't start
```bash
kubectl describe pod <pod-name> -n car-lot
kubectl logs <pod-name> -n car-lot
```

### Nodes not joining
```bash
sudo journalctl -u kubelet -f
```

### Image pull errors
```bash
sudo docker pull azexkush/car-lot-manager:latest
```

### Load Balancer health check still failing
Wait 5 more minutes and check again. Targets need time to become healthy.

---

## Once Everything is Working

✅ Pods are Running
✅ Service is up
✅ Application accessible at http://54.152.227.8
✅ Load Balancer targets showing "Healthy"

Test the application:
- Add a car
- Sell a car
- Verify data persists

Enjoy your production deployment! 🚀
