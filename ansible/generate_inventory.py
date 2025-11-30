import json
import subprocess
import sys

def get_terraform_outputs():
    try:
        # Run terraform output -json in the terraform directory
        result = subprocess.run(
            ["terraform", "output", "-json"],
            cwd="../terraform",
            capture_output=True,
            text=True,
            check=True
        )
        return json.loads(result.stdout)
    except subprocess.CalledProcessError as e:
        print(f"Error running terraform output: {e}")
        sys.exit(1)

def generate_inventory(outputs):
    ips = outputs["instance_ips"]["value"]
    
    # Assuming first IP is master, rest are workers
    master_ip = ips[0]
    worker_ips = ips[1:]
    
    inventory_content = "[master]\n"
    inventory_content += f"{master_ip} ansible_user=ubuntu ansible_ssh_private_key_file=../generated_key.pem ansible_ssh_common_args='-o StrictHostKeyChecking=no'\n\n"
    
    inventory_content += "[worker]\n"
    for ip in worker_ips:
        inventory_content += f"{ip} ansible_user=ubuntu ansible_ssh_private_key_file=../generated_key.pem ansible_ssh_common_args='-o StrictHostKeyChecking=no'\n"
        
    with open("inventory.ini", "w") as f:
        f.write(inventory_content)
    
    print("inventory.ini generated successfully.")

if __name__ == "__main__":
    outputs = get_terraform_outputs()
    generate_inventory(outputs)
