# Quick Fix Reference - Ansible Inventory Issue

## The Problem
```
Error: Failed to connect to the host via ssh: ssh: Could not resolve hostname ansible_user=ubuntu
```

## The Cause
Empty IP addresses in inventory file → Ansible treats `ansible_user=ubuntu` as hostname

## The Solution (Already Applied ✅)

### 1. GitHub Workflows Fixed
- ✅ `.github/workflows/deploy.yml` - Better IP extraction + validation
- ✅ `.github/workflows/cicd.yml` - Better IP extraction + validation + SSH wait

### 2. Inventory Generator Fixed
- ✅ `ansible/generate_inventory.py` - IP validation added

### 3. Validation Tools Added
- ✅ `validate-inventory.ps1` - Validate inventory format
- ✅ `regenerate-inventory.ps1` - Regenerate from Terraform

## What You Should Do Now

### Quick Deploy (Recommended)
```powershell
# 1. Commit changes
git add .
git commit -m "Fix Ansible inventory generation"
git push origin main

# 2. Monitor GitHub Actions
# Go to GitHub → Actions tab → Watch the workflow run
```

### Test Locally First
```powershell
# Validate current inventory
.\validate-inventory.ps1

# Regenerate from Terraform (if needed)
.\regenerate-inventory.ps1

# Validate again
.\validate-inventory.ps1
```

## Key Files Changed

| File | What Changed |
|------|--------------|
| `.github/workflows/deploy.yml` | IP extraction with jq, validation, inventory format |
| `.github/workflows/cicd.yml` | IP extraction with jq, validation, SSH wait, inventory format |
| `ansible/generate_inventory.py` | IP validation, better error handling |
| `validate-inventory.ps1` | NEW - Local validation tool |
| `regenerate-inventory.ps1` | NEW - Inventory regeneration tool |

## Verification Checklist

When the workflow runs, look for these in the logs:

- [ ] "Extracted IPs:" shows 3 valid IP addresses
- [ ] "Generated inventory.ini:" shows proper format with IPs
- [ ] "Inventory validation passed!" message appears
- [ ] "All instances are ready!" before Ansible runs
- [ ] "PLAY [Setup Kubernetes Cluster and NFS]" starts successfully
- [ ] No "Could not resolve hostname" errors

## If It Still Fails

### Check Terraform State
```powershell
cd terraform
terraform output instance_ips
# Should show: ["1.2.3.4", "5.6.7.8", "9.10.11.12"]
```

### Check AWS Resources
```powershell
aws ec2 describe-instances --filters "Name=tag:Name,Values=k8s-node-*" --query 'Reservations[].Instances[].State.Name'
# Should show: running, running, running
```

### Check Security Groups
- Port 22 (SSH) must be open from GitHub Actions IPs
- Or open from 0.0.0.0/0 temporarily for testing

## Common Issues

| Issue | Cause | Fix |
|-------|-------|-----|
| "IP1 is empty" | Terraform didn't create instances | Check Terraform state, re-run apply |
| "SSH timeout" | Instances not ready or SG blocked | Wait longer, check security groups |
| "No valid IP addresses" | Inventory format wrong | Re-run inventory generation |
| "Permission denied (publickey)" | Wrong SSH key | Check key permissions, path |

## Need More Help?

1. Check `FIXES_APPLIED.md` for detailed explanation
2. Check `ANSIBLE_FIX_SUMMARY.md` for technical details
3. Run `.\validate-inventory.ps1` to check local inventory
4. Check GitHub Actions logs for specific error messages

## Success Indicators

✅ Inventory has valid IPs on each line  
✅ Validation script passes  
✅ GitHub Actions shows "Inventory validation passed!"  
✅ Ansible playbook runs without connection errors  
✅ Kubernetes cluster deploys successfully  

---

**Status**: All fixes applied and ready to deploy! 🚀

Last Updated: December 1, 2025
