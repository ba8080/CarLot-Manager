# Ansible Inventory Fix Summary

## Problem Identified

The error `Failed to connect to the host via ssh: ssh: Could not resolve hostname ansible_user=ubuntu` indicates that Ansible is treating `ansible_user=ubuntu` as a hostname instead of a parameter. This happens when:

1. The inventory file has empty or null IP addresses
2. Environment variables are not properly expanded in GitHub Actions
3. The inventory file format is incorrect

## Root Cause

In the GitHub Actions workflow, when creating the inventory file using:
```bash
cat > ansible/inventory.ini << EOF
[master]
${{ env.MASTER_IP }} ansible_user=ubuntu ...
EOF
```

If `${{ env.MASTER_IP }}` is empty or null, the line becomes:
```
ansible_user=ubuntu ansible_ssh_private_key_file=...
```

This causes Ansible to treat `ansible_user=ubuntu` as the hostname.

## Fixes Applied

### 1. Enhanced Terraform Output Extraction (.github/workflows/deploy.yml)
- Added validation to check if IPs are empty or null
- Using `jq` for more reliable JSON parsing
- Added debug output to show extracted IPs
- Exit with error if IPs are invalid

### 2. Enhanced Terraform Output Extraction (.github/workflows/cicd.yml)
- Changed from regex extraction to `jq` JSON parsing
- Added validation for all IP addresses
- Added debug output

### 3. Improved Inventory Generator (ansible/generate_inventory.py)
- Added IP address validation function
- Checks for valid IP format before generating inventory
- Added `[all:vars]` section for Python interpreter
- Better error messages

### 4. Updated Inventory File Format
- Ensured proper formatting with blank lines between sections
- Added `[all:vars]` section with Python interpreter path

## Testing the Fix Locally

To test if the inventory file is properly formatted:

```powershell
# Check inventory file format
cat ansible\inventory.ini

# Verify IPs are present
Select-String -Pattern "^\d+\.\d+\.\d+\.\d+" ansible\inventory.ini

# Test Ansible connectivity (if you have Ansible installed)
ansible all -i ansible\inventory.ini -m ping
```

## For GitHub Actions

The workflow now includes:

1. **Validation Step**: Checks if IPs are extracted successfully
2. **Debug Output**: Prints extracted IPs for troubleshooting
3. **Inventory Validation**: Verifies IP addresses exist in inventory file
4. **Error Handling**: Exits with clear error message if validation fails

## Expected Inventory Format

```ini
[master]
1.2.3.4 ansible_user=ubuntu ansible_ssh_private_key_file=/tmp/key.pem ansible_ssh_common_args='-o StrictHostKeyChecking=no'

[worker]
5.6.7.8 ansible_user=ubuntu ansible_ssh_private_key_file=/tmp/key.pem ansible_ssh_common_args='-o StrictHostKeyChecking=no'
9.10.11.12 ansible_user=ubuntu ansible_ssh_private_key_file=/tmp/key.pem ansible_ssh_common_args='-o StrictHostKeyChecking=no'

[all:vars]
ansible_python_interpreter=/usr/bin/python3
```

## Next Steps

1. Commit and push the changes
2. Trigger GitHub Actions workflow
3. Check workflow logs for:
   - "Extracted IPs:" output
   - "Generated inventory.ini:" output
   - Successful Ansible connection

## If Issues Persist

Check:
1. Terraform outputs are being generated correctly
2. AWS credentials have permission to describe instances
3. Security groups allow SSH (port 22)
4. Instances are in running state
5. SSH key permissions are 400 or 600
