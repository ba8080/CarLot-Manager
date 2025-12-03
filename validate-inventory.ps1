#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Validates Ansible inventory file format and connectivity

.DESCRIPTION
    This script checks if the Ansible inventory file is properly formatted
    and contains valid IP addresses.

.EXAMPLE
    .\validate-inventory.ps1
#>

param(
    [string]$InventoryPath = "ansible\inventory.ini"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Ansible Inventory Validation" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if file exists
if (-not (Test-Path $InventoryPath)) {
    Write-Host "[X] Inventory file not found: $InventoryPath" -ForegroundColor Red
    exit 1
}

Write-Host "[OK] Inventory file found: $InventoryPath" -ForegroundColor Green
Write-Host ""

# Read inventory content
$content = Get-Content $InventoryPath -Raw
Write-Host "Current inventory content:" -ForegroundColor Yellow
Write-Host "----------------------------" -ForegroundColor Yellow
Write-Host $content
Write-Host "----------------------------" -ForegroundColor Yellow
Write-Host ""

# Validate IP addresses
Write-Host "Validating IP addresses..." -ForegroundColor Yellow

$ipPattern = '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}'
$ips = Select-String -Pattern $ipPattern -Path $InventoryPath | ForEach-Object { 
    if ($_.Line -match '^(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})') {
        $matches[1]
    }
}

if ($ips.Count -eq 0) {
    Write-Host "[X] No valid IP addresses found in inventory file!" -ForegroundColor Red
    Write-Host ""
    Write-Host "The inventory file should contain lines like:" -ForegroundColor Yellow
    Write-Host "1.2.3.4 ansible_user=ubuntu ansible_ssh_private_key_file=./key.pem" -ForegroundColor Yellow
    exit 1
}

Write-Host "[OK] Found $($ips.Count) IP address(es):" -ForegroundColor Green
foreach ($ip in $ips) {
    Write-Host "    - $ip" -ForegroundColor White
}
Write-Host ""

# Check for required sections
$requiredSections = @('[master]', '[worker]')
$missingSections = @()

foreach ($section in $requiredSections) {
    if ($content -notmatch [regex]::Escape($section)) {
        $missingSections += $section
    } else {
        Write-Host "[OK] Section found: $section" -ForegroundColor Green
    }
}

if ($missingSections.Count -gt 0) {
    Write-Host ""
    Write-Host "[WARNING] Missing sections:" -ForegroundColor Yellow
    foreach ($section in $missingSections) {
        Write-Host "    - $section" -ForegroundColor Yellow
    }
}

# Check for common issues
Write-Host ""
Write-Host "Checking for common issues..." -ForegroundColor Yellow

$issues = @()

# Check if ansible_user is on a line by itself
if ($content -match '^\s*ansible_user=') {
    $issues += "Found 'ansible_user=' at the start of a line (should be after IP address)"
}

# Check if lines have ansible_user parameter
$linesWithIP = Select-String -Pattern $ipPattern -Path $InventoryPath
foreach ($line in $linesWithIP) {
    if ($line.Line -notmatch 'ansible_user=') {
        $issues += "Line missing 'ansible_user=' parameter: $($line.Line)"
    }
}

if ($issues.Count -eq 0) {
    Write-Host "[OK] No formatting issues detected" -ForegroundColor Green
} else {
    Write-Host "[X] Found issues:" -ForegroundColor Red
    foreach ($issue in $issues) {
        Write-Host "    - $issue" -ForegroundColor Red
    }
    Write-Host ""
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Validation completed successfully!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Ansible is available
if (Get-Command ansible -ErrorAction SilentlyContinue) {
    Write-Host "Ansible is installed. You can test connectivity with:" -ForegroundColor Yellow
    Write-Host "  ansible all -i $InventoryPath -m ping" -ForegroundColor White
} else {
    Write-Host "Note: Ansible is not installed. Install it to test connectivity." -ForegroundColor Yellow
}

exit 0
