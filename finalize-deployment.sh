#!/bin/bash
# Finalize deployment - Run on master node after Terraform creates infrastructure

set -e

echo "========================================"
echo "FINALIZING DEPLOYMENT ON KUBERNETES"
echo "========================================"

# Wait for kubeconfig to be available
echo "[1/6] Waiting for kubeconfig..."
for i in {1..30}; do
  if [ -f ~/.kube/config ]; then
    echo "  [OK] kubeconfig found"
    break
  fi
  echo "  Attempt $i/30..."
  sleep 10
done

# Wait for nodes to be ready
echo "[2/6] Waiting for Kubernetes nodes to be ready..."
kubectl wait --for=condition=Ready node --all --timeout=600s || true

# Check node status
echo "[3/6] Kubernetes cluster status:"
kubectl get nodes

# Create storage class for NFS
echo "[4/6] Creating NFS storage class..."
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

# Create namespace
echo "[5/6] Creating car-lot namespace..."
kubectl create namespace car-lot || true

# Deploy application with Helm
echo "[6/6] Deploying Car Lot Manager..."

cd /home/ubuntu/CarLot-Manager

# Create and deploy Helm chart
helm upgrade --install car-lot ./helm/car-lot \
  -n car-lot \
  --create-namespace \
  --set image.repository=ba8080/car-lot-manager \
  --set image.tag=latest \
  --set replicaCount=2 \
  --set service.type=NodePort \
  --set service.port=30080 \
  --set service.targetPort=8501 \
  --set persistence.enabled=true \
  --set persistence.storageClassName=nfs-storage \
  --set persistence.size=5Gi \
  --timeout 10m0s \
  --wait=false

echo ""
echo "========================================"
echo "DEPLOYMENT FINALIZED"
echo "========================================"
echo ""
echo "Wait 2-3 minutes for pods to start, then check:"
echo "  kubectl get pods -n car-lot"
echo "  kubectl get svc -n car-lot"
echo ""
echo "Load Balancer targets should become HEALTHY soon"
echo "Application will be accessible at:"
echo "  http://<Master-IP>"
echo ""
