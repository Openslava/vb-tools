<#
.SYNOPSIS
    Quick Ansible setup for WSL
.PARAMETER distroName
    WSL distribution name (default: "OracleLinux_8_10")
.PARAMETER force
    Forces Ansible reinstallation
#>
[CmdletBinding()]
param(
    [string]$distroName = "OracleLinux_8_10",
    [switch]$force
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$repoRoot = Split-Path -Parent $scriptDir

Write-Host "🚀 Setting up Ansible in $distroName" -ForegroundColor Cyan

# Setup WSL first
& "$repoRoot\wsl\01_set_wsl.ps1" -distroName $distroName -force:$force

# Install Ansible
$wslRepoRoot = (wsl -d $distroName -e wslpath "$repoRoot").Trim()
$script = @"
set -e
cd '$wslRepoRoot'
$(if ($force) { "export FORCE_MODE=true" } else { "export FORCE_MODE=false" })
./ansible/01_set_ansible.sh
"@

wsl -d $distroName -u root -- bash -c "$script"

Write-Host "✅ Ansible setup complete!" -ForegroundColor Green
Write-Host "🧪 Test: wsl -d $distroName -- ansible --version" -ForegroundColor Yellow
