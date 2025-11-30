#!/bin/bash
# Car Lot Manager - DevOps Final Project Verification Script
# This script performs end-to-end validation of all project components

set -e

echo "=============================================="
echo "Car Lot Manager - DevOps Project Verification"
echo "=============================================="
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

TESTS_PASSED=0
TESTS_FAILED=0

test_section() {
    echo -e "${YELLOW}[TEST] $1${NC}"
}

test_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((TESTS_PASSED++))
}

test_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((TESTS_FAILED++))
}

# Test 1: Python Tests
test_section "Running Python Unit Tests"
if python -m unittest discover tests 2>&1 | grep -q "OK"; then
    test_pass "All unit tests passed"
else
    test_fail "Unit tests failed"
fi
echo ""

# Test 2: Storage/Persistence
test_section "Checking File-based Persistence"
if [ -f "inventory.json" ]; then
    test_pass "inventory.json exists with dummy data"
    if grep -q "Toyota" inventory.json && grep -q "Honda" inventory.json; then
        test_pass "Dummy data contains expected cars"
    else
        test_fail "Dummy data missing expected entries"
    fi
else
    test_fail "inventory.json not found"
fi
echo ""

# Test 3: Dockerfile
test_section "Validating Dockerfile"
if [ -f "Dockerfile" ]; then
    test_pass "Dockerfile exists"
    if grep -q "FROM python:3.11-slim" Dockerfile; then
        test_pass "Base image is Python 3.11-slim"
    else
        test_fail "Incorrect Python base image"
    fi
    if grep -q "EXPOSE 8501" Dockerfile; then
        test_pass "Streamlit port 8501 exposed"
    else
        test_fail "Streamlit port not exposed"
    fi
else
    test_fail "Dockerfile not found"
fi
echo ""

# Test 4: Terraform Configuration
test_section "Validating Terraform Configuration"
if [ -d "terraform" ]; then
    test_pass "terraform/ directory exists"
    if [ -f "terraform/main.tf" ]; then
        test_pass "main.tf exists"
        # Check for key resources
        if grep -q "aws_instance" terraform/main.tf && grep -q "count.*= 3" terraform/main.tf; then
            test_pass "3 EC2 instances configured"
        else
            test_fail "3 EC2 instances not found in configuration"
        fi
        if grep -q "aws_lb" terraform/main.tf; then
            test_pass "Load Balancer configured"
        else
            test_fail "Load Balancer not found"
        fi
        if grep -q "aws_vpc" terraform/main.tf && grep -q "aws_subnet" terraform/main.tf; then
            test_pass "VPC and Subnets configured"
        else
            test_fail "Network components missing"
        fi
    else
        test_fail "main.tf not found"
    fi
else
    test_fail "terraform/ directory not found"
fi
echo ""

# Test 5: Ansible Configuration
test_section "Validating Ansible Configuration"
if [ -d "ansible" ]; then
    test_pass "ansible/ directory exists"
    if [ -f "ansible/playbook.yml" ]; then
        test_pass "playbook.yml exists"
        if grep -q "kubeadm" ansible/playbook.yml; then
            test_pass "Kubernetes (kubeadm) installation included"
        else
            test_fail "Kubernetes installation not found"
        fi
        if grep -q "nfs" ansible/playbook.yml; then
            test_pass "NFS configuration included"
        else
            test_fail "NFS configuration not found"
        fi
        if grep -q "docker" ansible/playbook.yml; then
            test_pass "Docker installation included"
        else
            test_fail "Docker installation not found"
        fi
    else
        test_fail "playbook.yml not found"
    fi
else
    test_fail "ansible/ directory not found"
fi
echo ""

# Test 6: Helm Charts
test_section "Validating Helm Charts"
if [ -d "helm/car-lot" ]; then
    test_pass "helm/car-lot/ directory exists"
    if [ -f "helm/car-lot/Chart.yaml" ]; then
        test_pass "Chart.yaml exists"
    else
        test_fail "Chart.yaml not found"
    fi
    if [ -f "helm/car-lot/values.yaml" ]; then
        test_pass "values.yaml exists"
    else
        test_fail "values.yaml not found"
    fi
    if [ -f "helm/car-lot/templates/deployment.yaml" ]; then
        test_pass "deployment.yaml exists"
        if grep -q "azexkush/car-lot-manager" helm/car-lot/templates/deployment.yaml; then
            test_pass "Correct Docker image reference"
        else
            test_fail "Incorrect Docker image reference"
        fi
    else
        test_fail "deployment.yaml not found"
    fi
    if [ -f "helm/car-lot/templates/service.yaml" ]; then
        test_pass "service.yaml exists"
        if grep -q "30080" helm/car-lot/templates/service.yaml; then
            test_pass "NodePort 30080 configured"
        else
            test_fail "NodePort not properly configured"
        fi
    else
        test_fail "service.yaml not found"
    fi
else
    test_fail "helm/car-lot/ directory not found"
fi
echo ""

# Test 7: CI/CD Pipeline
test_section "Validating GitHub Actions CI/CD"
if [ -f ".github/workflows/deploy.yml" ]; then
    test_pass ".github/workflows/deploy.yml exists"
    WORKFLOW_FILE=".github/workflows/deploy.yml"
    
    if grep -q "python -m unittest" "$WORKFLOW_FILE"; then
        test_pass "Unit tests in pipeline"
    else
        test_fail "Unit tests not in pipeline"
    fi
    
    if grep -q "docker/build-push-action" "$WORKFLOW_FILE"; then
        test_pass "Docker build & push in pipeline"
    else
        test_fail "Docker build & push not in pipeline"
    fi
    
    if grep -q "terraform apply" "$WORKFLOW_FILE"; then
        test_pass "Terraform apply in pipeline"
    else
        test_fail "Terraform apply not in pipeline"
    fi
    
    if grep -q "ansible-playbook" "$WORKFLOW_FILE"; then
        test_pass "Ansible playbook in pipeline"
    else
        test_fail "Ansible playbook not in pipeline"
    fi
    
    if grep -q "helm upgrade" "$WORKFLOW_FILE"; then
        test_pass "Helm deployment in pipeline"
    else
        test_fail "Helm deployment not in pipeline"
    fi
else
    test_fail ".github/workflows/deploy.yml not found"
fi
echo ""

# Test 8: Documentation
test_section "Validating Documentation"
if [ -f "README.md" ]; then
    test_pass "README.md exists"
    if grep -q "Prerequisites" README.md; then
        test_pass "Prerequisites section present"
    fi
    if grep -q "Clone the Repository" README.md; then
        test_pass "Clone instructions present"
    fi
    if grep -q "AWS Configuration" README.md; then
        test_pass "AWS credentials documentation present"
    fi
    if grep -q "Triggering the Pipeline" README.md; then
        test_pass "CI/CD trigger instructions present"
    fi
else
    test_fail "README.md not found"
fi

if [ -f "USER_GUIDE.md" ]; then
    test_pass "USER_GUIDE.md exists"
else
    test_fail "USER_GUIDE.md not found"
fi
echo ""

# Test 9: Application Features
test_section "Checking Python Application Code"
if [ -f "website/app.py" ]; then
    test_pass "website/app.py exists (Streamlit app)"
    if grep -q "def add_car" app/functions.py || grep -q "def add_car" website/app.py; then
        test_pass "Add car functionality exists"
    fi
    if grep -q "def sell_car" app/functions.py || grep -q "def sell_car" website/app.py; then
        test_pass "Sell car functionality exists"
    fi
else
    test_fail "website/app.py not found"
fi
echo ""

# Summary
echo "=============================================="
echo "Test Summary"
echo "=============================================="
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Failed: $TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}All checks PASSED!${NC}"
    echo ""
    echo "Next steps to deploy:"
    echo "1. Ensure GitHub secrets are configured:"
    echo "   - AWS_ACCESS_KEY_ID"
    echo "   - AWS_SECRET_ACCESS_KEY"
    echo "   - AWS_SESSION_TOKEN"
    echo "   - DOCKERHUB_USERNAME"
    echo "   - DOCKERHUB_TOKEN"
    echo ""
    echo "2. Push to main branch:"
    echo "   git push origin main"
    echo ""
    echo "3. Monitor GitHub Actions:"
    echo "   - Tests run first"
    echo "   - Docker build & push"
    echo "   - Terraform provisions infrastructure"
    echo "   - Ansible configures Kubernetes"
    echo "   - Helm deploys the application"
    echo ""
    echo "4. Access the application:"
    echo "   - Check Terraform outputs for ALB DNS name"
    echo "   - Visit: http://[ALB-DNS-NAME]"
    exit 0
else
    echo -e "${RED}Some checks failed. Please review and fix issues before deployment.${NC}"
    exit 1
fi
