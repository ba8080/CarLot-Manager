#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Regenerate Ansible inventory from Terraform outputs

.DESCRIPTION
    Extracts instance IPs from Terraform state and regenerates the Ansible inventory file.
    Useful for updating inventory after infrastructure changes.

.EXAMPLE
    .\regenerate-inventory.ps1
#>

param(
    [string]$TerraformDir = "terraform",
    [string]$OutputFile = "ansible\inventory.ini"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Regenerating Ansible Inventory" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Terraform directory exists
if (-not (Test-Path $TerraformDir)) {
    Write-Host "[ERROR] Terraform directory not found: $TerraformDir" -ForegroundColor Red
    exit 1
}

# Change to Terraform directory
Push-Location $TerraformDir

try {
    # Get Terraform outputs
    Write-Host "Extracting instance IPs from Terraform..." -ForegroundColor Yellow
    
    $outputJson = terraform output -json instance_ips 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] Failed to get Terraform outputs" -ForegroundColor Red
        Write-Host $outputJson -ForegroundColor Red
        exit 1
    }
    
    $ips = $outputJson | ConvertFrom-Json | Select-Object -ExpandProperty value
    
    if ($null -eq $ips -or $ips.Count -lt 3) {
        Write-Host "[ERROR] Expected at least 3 IPs, got $($ips.Count)" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "[OK] Found $($ips.Count) instance IPs:" -ForegroundColor Green
    for ($i = 0; $i -lt $ips.Count; $i++) {
        $role = if ($i -eq 0) { "Master" } else { "Worker $i" }
        Write-Host "    [$i] $role : $($ips[$i])" -ForegroundColor White
    }
    Write-Host ""
    
    # Get SSH private key
    Write-Host "Extracting SSH private key..." -ForegroundColor Yellow
    $sshKey = terraform output -raw ssh_private_key
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[WARNING] Could not extract SSH key" -ForegroundColor Yellow
    } else {
        $keyPath = Join-Path $PSScriptRoot "ansible\generated_key.pem"
        $sshKey | Set-Content -Path $keyPath -NoNewline
        Write-Host "[OK] SSH key saved to: $keyPath" -ForegroundColor Green
        
        # Note: On Linux/Mac, you would run: chmod 400 $keyPath
        if ($IsLinux -or $IsMacOS) {
            chmod 400 $keyPath
        }
    }
    Write-Host ""
    
} finally {
    Pop-Location
}

# Generate inventory content
Write-Host "Generating inventory file..." -ForegroundColor Yellow

$masterIP = $ips[0]
$workerIPs = $ips[1..($ips.Count - 1)]

$inventoryContent = @"
[master]
$masterIP ansible_user=ubuntu ansible_ssh_private_key_file=./generated_key.pem ansible_ssh_common_args='-o StrictHostKeyChecking=no'

[worker]
"@

foreach ($ip in $workerIPs) {
    $inventoryContent += "`n$ip ansible_user=ubuntu ansible_ssh_private_key_file=./generated_key.pem ansible_ssh_common_args='-o StrictHostKeyChecking=no'"
}

$inventoryContent += @"


[all:vars]
ansible_python_interpreter=/usr/bin/python3
"@

# Write inventory file
$inventoryContent | Set-Content -Path $OutputFile -NoNewline

Write-Host "[OK] Inventory file created: $OutputFile" -ForegroundColor Green
Write-Host ""

# Validate the generated inventory
Write-Host "Validating generated inventory..." -ForegroundColor Yellow
Write-Host "----------------------------" -ForegroundColor Gray
Write-Host $inventoryContent
Write-Host "----------------------------" -ForegroundColor Gray
Write-Host ""

# Check for valid IPs
$ipCount = ([regex]::Matches($inventoryContent, '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}')).Count

if ($ipCount -eq $ips.Count) {
    Write-Host "[OK] Validation passed: All $ipCount IPs present in inventory" -ForegroundColor Green
} else {
    Write-Host "[WARNING] Expected $($ips.Count) IPs, found $ipCount in inventory" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Inventory regeneration complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Validate: .\validate-inventory.ps1" -ForegroundColor White
Write-Host "  2. Test connection (if Ansible installed):" -ForegroundColor White
Write-Host "     ansible all -i $OutputFile -m ping" -ForegroundColor White
Write-Host "  3. Run playbook:" -ForegroundColor White
Write-Host "     ansible-playbook -i $OutputFile ansible\playbook.yml" -ForegroundColor White
Write-Host ""

exit 0
