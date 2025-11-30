import json
import subprocess
import sys
import os

def get_terraform_outputs():
    try:
        # Get the workspace root directory
        workspace = os.environ.get('GITHUB_WORKSPACE', os.path.abspath('..'))
        terraform_dir = os.path.join(workspace, 'terraform')
        
        # Run terraform output -json in the terraform directory
        result = subprocess.run(
            ["terraform", "output", "-json"],
            cwd=terraform_dir,
            capture_output=True,
            text=True,
            check=True
        )
        
        # Filter out GitHub Actions command lines and find JSON content
        output = result.stdout
        
        # Remove lines starting with [command]
        lines = output.split('\n')
        filtered_lines = [line for line in lines if not line.startswith('[command]')]
        filtered_output = '\n'.join(filtered_lines)
        
        # Find the first { and last } to extract only the JSON object
        first_brace = filtered_output.find('{')
        last_brace = filtered_output.rfind('}')
        
        if first_brace == -1 or last_brace == -1:
            raise ValueError("No JSON object found in terraform output")
        
        json_output = filtered_output[first_brace:last_brace+1]
        
        return json.loads(json_output)
    except subprocess.CalledProcessError as e:
        print(f"Error running terraform output: {e}")
        print(f"stdout: {e.stdout}")
        print(f"stderr: {e.stderr}")
        sys.exit(1)
    except (json.JSONDecodeError, ValueError) as e:
        print(f"Error parsing JSON: {e}")
        print(f"Filtered output was: {json_output if 'json_output' in locals() else filtered_output}")
        sys.exit(1)

def generate_inventory(outputs):
    ips = outputs["instance_ips"]["value"]
    
    # Assuming first IP is master, rest are workers
    master_ip = ips[0]
    worker_ips = ips[1:]
    
    # Use /tmp for SSH key in GitHub Actions
    ssh_key_path = "/tmp/generated_key.pem"
    
    inventory_content = "[master]\n"
    inventory_content += f"{master_ip} ansible_user=ubuntu ansible_ssh_private_key_file={ssh_key_path} ansible_ssh_common_args='-o StrictHostKeyChecking=no'\n\n"
    
    inventory_content += "[worker]\n"
    for ip in worker_ips:
        inventory_content += f"{ip} ansible_user=ubuntu ansible_ssh_private_key_file={ssh_key_path} ansible_ssh_common_args='-o StrictHostKeyChecking=no'\n"
        
    with open("inventory.ini", "w") as f:
        f.write(inventory_content)
    
    print("inventory.ini generated successfully.")

if __name__ == "__main__":
    outputs = get_terraform_outputs()
    generate_inventory(outputs)
