# Ansible Quick Setup for WSL/Oracle Linux
# This script sets up Ansible in a WSL environment

[CmdletBinding()]
param(
    [string]$distroName = "OracleLinux_8_10",
    [switch]$forse
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$repoRoot = Split-Path -Parent $scriptDir

Write-Host "=== Ansible Quick Setup ==="
Write-Host "WSL Distribution: $distroName"
if ($forse) { Write-Host "Force mode: ENABLED (will reinstall Ansible)" }
Write-Host ""

# Ensure WSL is setup first
Write-Host "Checking WSL distribution: $distroName"
& "$repoRoot\wsl\01_set_wsl.ps1" -distroName $distroName -forse:$forse

# Fix line endings in bash scripts
Write-Host "Converting Ansible script line endings..."
$wslRepoRoot = (wsl -d $distroName -e wslpath "$repoRoot").Trim()
wsl -d $distroName -u root -- bash -c "sed -i 's/\r$//' '$wslRepoRoot/ansible/'*.sh"

Write-Host "Starting Ansible installation..."

# Resolve repo root path inside WSL
$wslRepoRoot = (wsl -d $distroName -e wslpath "$repoRoot").Trim()
$commands = @(
    "set -e",
    "cd '$wslRepoRoot'",
    $(if ($forse) { "export FORCE_MODE=true" } else { "export FORCE_MODE=false" }),
    "./ansible/01_set_ansible.sh"
)

$script = $commands -join "`n"

# Run script in WSL as root
Write-Host "Executing Ansible setup in WSL..."
wsl -d $distroName -u root -- bash -c "$script"

Write-Host ""
Write-Host "=== Ansible Setup Complete ==="
Write-Host "To use Ansible: wsl -d $distroName"
Write-Host "Check version: ansible --version"
Write-Host "Create inventory: ansible-inventory --list"
Write-Host ""
Write-Host "Next steps:"
Write-Host "1. Create inventory files"
Write-Host "2. Write playbooks"
Write-Host "3. Run: ansible-playbook playbook.yml"
