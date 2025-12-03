#!/bin/bash

# Debug and Fix Deployment Script
echo "=== Car Lot Manager Deployment Debug ==="

# Get infrastructure details from terraform
cd terraform
MASTER_IP=$(terraform output -raw instance_ips | jq -r '.[0]' 2>/dev/null || echo "3.94.190.169")
ALB_DNS=$(terraform output -raw alb_dns_name 2>/dev/null || echo "carlot-alb-b899581d-1804767734.us-east-1.elb.amazonaws.com")

# Extract SSH key
terraform output -raw ssh_private_key > /tmp/ssh_key.pem 2>/dev/null
chmod 400 /tmp/ssh_key.pem

echo "Master IP: $MASTER_IP"
echo "ALB DNS: $ALB_DNS"
echo ""

# Function to run commands on master node
run_on_master() {
    ssh -i /tmp/ssh_key.pem -o StrictHostKeyChecking=no ubuntu@$MASTER_IP "$1"
}

echo "1. Checking cluster status..."
run_on_master "kubectl get nodes"
echo ""

echo "2. Checking pod status..."
run_on_master "kubectl get pods -o wide"
echo ""

echo "3. Checking services..."
run_on_master "kubectl get svc"
echo ""

echo "4. Checking if pods are running..."
RUNNING_PODS=$(run_on_master "kubectl get pods --no-headers | grep -c Running" || echo "0")
echo "Running pods: $RUNNING_PODS"

if [ "$RUNNING_PODS" = "0" ]; then
    echo ""
    echo "❌ No pods are running! Redeploying application..."
    
    # Redeploy the application
    echo "Copying Helm chart to master..."
    scp -i /tmp/ssh_key.pem -o StrictHostKeyChecking=no -r ../helm ubuntu@$MASTER_IP:/tmp/
    
    echo "Redeploying with Helm..."
    run_on_master "
        cd /tmp
        helm uninstall car-lot-manager --ignore-not-found
        sleep 10
        helm install car-lot-manager ./helm/car-lot \
          --set image.repository=azexkush/car-lot-manager \
          --set image.tag=latest \
          --set nfs.server=\$(hostname -I | awk '{print \$1}') \
          --wait \
          --timeout 10m
    "
    
    echo ""
    echo "Waiting for pods to be ready..."
    sleep 30
    run_on_master "kubectl get pods -o wide"
fi

echo ""
echo "5. Testing NodePort service directly..."
run_on_master "curl -s http://localhost:30080/health || echo 'NodePort not responding'"

echo ""
echo "6. Checking if application is accessible from worker nodes..."
WORKER1_IP="54.91.72.4"
WORKER2_IP="54.242.165.45"

for worker_ip in $WORKER1_IP $WORKER2_IP; do
    echo "Testing from $worker_ip..."
    ssh -i /tmp/ssh_key.pem -o StrictHostKeyChecking=no ubuntu@$worker_ip "curl -s http://localhost:30080/health || echo 'Not accessible from $worker_ip'" &
done
wait

echo ""
echo "7. Testing Load Balancer..."
echo "Testing: http://$ALB_DNS/health"
curl -s --connect-timeout 10 "http://$ALB_DNS/health" || echo "Load Balancer not responding"

echo ""
echo "=== Deployment Status Summary ==="
echo "Application URL: http://$ALB_DNS"
echo ""
echo "If still getting 504 errors, the issue might be:"
echo "1. Pods not running (check kubectl get pods)"
echo "2. Service not properly configured"
echo "3. Load balancer target group not healthy"
echo ""
echo "Run this script again to retry deployment if needed."