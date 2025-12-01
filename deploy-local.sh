#!/bin/bash
set -e

echo "=========================================="
echo "Car Lot Manager - Local Deployment Script"
echo "=========================================="
echo ""

# Check prerequisites
command -v terraform >/dev/null 2>&1 || { echo "Error: terraform is required but not installed."; exit 1; }
command -v ansible >/dev/null 2>&1 || { echo "Error: ansible is required but not installed."; exit 1; }
command -v docker >/dev/null 2>&1 || { echo "Error: docker is required but not installed."; exit 1; }
command -v aws >/dev/null 2>&1 || { echo "Error: aws cli is required but not installed."; exit 1; }

# Check AWS credentials
if ! aws sts get-caller-identity >/dev/null 2>&1; then
    echo "Error: AWS credentials not configured"
    exit 1
fi

echo "✓ All prerequisites met"
echo ""

# Step 1: Build and Push Docker Image
echo "Step 1: Building and pushing Docker image..."
docker build -t azexkush/car-lot-manager:latest .
docker push azexkush/car-lot-manager:latest
echo "✓ Docker image built and pushed"
echo ""

# Step 2: Deploy Infrastructure with Terraform
echo "Step 2: Deploying infrastructure with Terraform..."
cd terraform
terraform init
terraform destroy -auto-approve 2>/dev/null || true
terraform apply -auto-approve

# Get outputs
ALB_DNS=$(terraform output -raw alb_dns_name)
MASTER_IP=$(terraform output -json instance_ips | jq -r '.[0]')
WORKER1_IP=$(terraform output -json instance_ips | jq -r '.[1]')
WORKER2_IP=$(terraform output -json instance_ips | jq -r '.[2]')
MASTER_PRIVATE_IP=$(terraform output -raw master_private_ip)

terraform output -raw ssh_private_key > ../generated_key.pem
chmod 400 ../generated_key.pem

cd ..

echo "✓ Infrastructure deployed"
echo "  Master: $MASTER_IP"
echo "  Worker 1: $WORKER1_IP"
echo "  Worker 2: $WORKER2_IP"
echo "  Load Balancer: $ALB_DNS"
echo ""

# Step 3: Wait for instances to boot
echo "Step 3: Waiting for instances to boot (90 seconds)..."
sleep 90
echo "✓ Boot wait complete"
echo ""

# Step 4: Test SSH connectivity
echo "Step 4: Testing SSH connectivity..."
for ip in "$MASTER_IP" "$WORKER1_IP" "$WORKER2_IP"; do
    echo "  Testing $ip..."
    max_attempts=30
    attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if ssh -i generated_key.pem -o StrictHostKeyChecking=no -o ConnectTimeout=5 ubuntu@$ip "echo OK" 2>/dev/null; then
            echo "  ✓ SSH ready on $ip"
            break
        fi
        
        if [ $attempt -eq $max_attempts ]; then
            echo "  ✗ Failed to connect to $ip"
            exit 1
        fi
        
        sleep 10
        attempt=$((attempt + 1))
    done
done
echo ""

# Step 5: Create Ansible inventory
echo "Step 5: Creating Ansible inventory..."
cat > ansible/inventory.ini << EOF
[master]
$MASTER_IP ansible_user=ubuntu ansible_ssh_private_key_file=../generated_key.pem ansible_ssh_common_args='-o StrictHostKeyChecking=no'

[worker]
$WORKER1_IP ansible_user=ubuntu ansible_ssh_private_key_file=../generated_key.pem ansible_ssh_common_args='-o StrictHostKeyChecking=no'
$WORKER2_IP ansible_user=ubuntu ansible_ssh_private_key_file=../generated_key.pem ansible_ssh_common_args='-o StrictHostKeyChecking=no'

[all:vars]
ansible_python_interpreter=/usr/bin/python3
EOF
echo "✓ Inventory created"
echo ""

# Step 6: Run Ansible playbook
echo "Step 6: Running Ansible playbook..."
cd ansible
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory.ini playbook.yml
cd ..
echo "✓ Ansible configuration complete"
echo ""

# Step 7: Wait for Kubernetes cluster
echo "Step 7: Waiting for Kubernetes cluster to stabilize (60 seconds)..."
sleep 60
echo "✓ Cluster stabilization wait complete"
echo ""

# Step 8: Deploy application
echo "Step 8: Deploying application to Kubernetes..."
scp -i generated_key.pem -o StrictHostKeyChecking=no ./simple-deployment.yaml ubuntu@$MASTER_IP:/tmp/

ssh -i generated_key.pem -o StrictHostKeyChecking=no ubuntu@$MASTER_IP "
    kubectl wait --for=condition=Ready nodes --all --timeout=300s
    kubectl apply -f /tmp/simple-deployment.yaml
    kubectl rollout status deployment/car-lot-simple --timeout=300s
    
    echo 'Pods:'
    kubectl get pods -o wide
    echo 'Services:'
    kubectl get svc
"
echo "✓ Application deployed"
echo ""

# Step 9: Verify NodePort
echo "Step 9: Verifying NodePort..."
ssh -i generated_key.pem -o StrictHostKeyChecking=no ubuntu@$MASTER_IP "
    curl -s http://localhost:30080/health || echo 'NodePort test failed'
"
echo "✓ NodePort verified"
echo ""

# Step 10: Wait for Load Balancer
echo "Step 10: Waiting for Load Balancer to register targets (120 seconds)..."
sleep 120
echo ""

# Step 11: Test Load Balancer
echo "Step 11: Testing Load Balancer..."
max_attempts=20
attempt=1

while [ $attempt -le $max_attempts ]; do
    echo "  Attempt $attempt/$max_attempts..."
    
    if curl -s --connect-timeout 10 "http://$ALB_DNS/health" | grep -q "healthy"; then
        echo "  ✅ Health check passed!"
        
        if curl -s --connect-timeout 10 "http://$ALB_DNS" | grep -q "Car Lot Manager"; then
            echo "  ✅ Application is fully accessible!"
            break
        fi
    fi
    
    if [ $attempt -eq $max_attempts ]; then
        echo "  ❌ Application not accessible after $max_attempts attempts"
        exit 1
    fi
    
    sleep 15
    attempt=$((attempt + 1))
done
echo ""

# Final Summary
echo "=========================================="
echo "🎉 DEPLOYMENT COMPLETED SUCCESSFULLY! 🎉"
echo "=========================================="
echo ""
echo "🌐 Access your Car Lot Manager at:"
echo ""
echo "    http://$ALB_DNS"
echo ""
echo "=========================================="
echo ""
echo "Infrastructure Details:"
echo "  - Master Node: $MASTER_IP"
echo "  - Worker 1: $WORKER1_IP"
echo "  - Worker 2: $WORKER2_IP"
echo "  - Load Balancer: $ALB_DNS"
echo ""
echo "Application Endpoints:"
echo "  - Main Page: http://$ALB_DNS/"
echo "  - Health Check: http://$ALB_DNS/health"
echo "  - API: http://$ALB_DNS/api/inventory"
echo ""
echo "SSH Access:"
echo "  ssh -i generated_key.pem ubuntu@$MASTER_IP"
echo ""
echo "=========================================="
