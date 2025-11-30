#!/usr/bin/env python3
"""Check deployment status of Car Lot Manager on AWS"""

import subprocess
import sys
import time

master_ip = "54.152.227.8"
key_file = "generated_key.pem"

def ssh_command(cmd):
    """Run SSH command and return output"""
    try:
        result = subprocess.run(
            f'ssh -i "{key_file}" -o StrictHostKeyChecking=no ubuntu@{master_ip} "{cmd}"',
            shell=True,
            capture_output=True,
            text=True,
            timeout=10
        )
        return result.stdout.strip(), result.returncode
    except subprocess.TimeoutExpired:
        return "", 1

def main():
    print("\n" + "="*50)
    print("CAR LOT MANAGER - DEPLOYMENT STATUS")
    print("="*50 + "\n")
    
    print(f"Master IP: {master_ip}")
    print(f"SSH Key: {key_file}\n")
    
    # 1. Check if master is reachable
    print("[1/4] Checking if master is reachable...")
    output, code = ssh_command("echo 'OK'")
    if code == 0:
        print("✓ Master is reachable\n")
    else:
        print("✗ Cannot reach master. Still starting?\n")
        return
    
    # 2. Check bootstrap progress
    print("[2/4] Checking bootstrap script progress...")
    output, code = ssh_command("ls -la /tmp/kubernetes-bootstrap.sh 2>/dev/null && echo 'Script present' || echo 'Script not found'")
    print(output)
    
    # 3. Check if kubectl is available
    print("\n[3/4] Checking Kubernetes status...")
    output, code = ssh_command("kubectl version --client 2>/dev/null || echo 'kubectl not ready'")
    if "Kubernetes" in output or "GitVersion" in output:
        print("✓ Kubernetes tools installed\n")
    else:
        print("⏳ Kubernetes tools still installing\n")
    
    # 4. Check pods
    print("[4/4] Checking application pods...")
    output, code = ssh_command("kubectl get pods -n car-lot 2>/dev/null || echo 'Pods not deployed yet'")
    print(output)
    
    print("\n" + "="*50)
    print("TIMELINE:")
    print("  0-2 min:  System startup")
    print("  2-4 min:  Docker and Kubernetes tools")
    print("  4-7 min:  Kubernetes master init")
    print("  7-9 min:  Helm chart deployment")
    print("  9+ min:   Pods running")
    print("\nOnce pods show 'Running':")
    print(f"  Open: http://{master_ip}")
    print("\n" + "="*50 + "\n")

if __name__ == "__main__":
    main()
