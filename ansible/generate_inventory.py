#!/usr/bin/env python3
import sys
import re

def is_valid_ip(ip):
    """Validate IP address format"""
    pattern = r'^(\d{1,3}\.){3}\d{1,3}$'
    if not re.match(pattern, ip):
        return False
    octets = ip.split('.')
    return all(0 <= int(octet) <= 255 for octet in octets)

def generate_inventory(ips):
    """Generate Ansible inventory from list of IP addresses"""
    if len(ips) < 1:
        print("Error: Need at least 1 IP address")
        sys.exit(1)
    
    # Validate all IPs
    for ip in ips:
        if not is_valid_ip(ip):
            print(f"Error: Invalid IP address: {ip}")
            sys.exit(1)
    
    # First IP is master, rest are workers
    master_ip = ips[0]
    worker_ips = ips[1:] if len(ips) > 1 else []
    
    # Use /tmp for SSH key in GitHub Actions
    ssh_key_path = "/tmp/generated_key.pem"
    
    inventory_content = "[master]\n"
    inventory_content += f"{master_ip} ansible_user=ubuntu ansible_ssh_private_key_file={ssh_key_path} ansible_ssh_common_args='-o StrictHostKeyChecking=no'\n\n"
    
    if worker_ips:
        inventory_content += "[worker]\n"
        for ip in worker_ips:
            inventory_content += f"{ip} ansible_user=ubuntu ansible_ssh_private_key_file={ssh_key_path} ansible_ssh_common_args='-o StrictHostKeyChecking=no'\n"
        inventory_content += "\n"
    
    inventory_content += "[all:vars]\n"
    inventory_content += "ansible_python_interpreter=/usr/bin/python3\n"
    
    with open("inventory.ini", "w") as f:
        f.write(inventory_content)
    
    print("inventory.ini generated successfully.")
    print(f"Master: {master_ip}")
    if worker_ips:
        print(f"Workers: {', '.join(worker_ips)}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 generate_inventory.py <ip1> <ip2> <ip3> ...")
        sys.exit(1)
    
    # Get IPs from command line arguments
    ips = sys.argv[1:]
    generate_inventory(ips)
