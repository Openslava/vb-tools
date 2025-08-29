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

$weblogicScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$repoRoot = Split-Path -Parent $weblogicScriptDir

Write-Host "### 00_quick_start.ps1 - Setting up Ansible on $distroName" -ForegroundColor Cyan
Write-Host " Domain: $domainName | Port: $adminPort | User: $adminUser" -ForegroundColor Yellow

# Convert all sh files in subfolders to Unix line endings using PowerShell
Get-ChildItem -Path "$weblogicScriptDir" -Filter "*.sh" -Recurse | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    $content = $content -replace "`r`n", "`n"
    Set-Content $_.FullName -Value $content -NoNewline
}

# check WSL  distro is installed
$wslDistros = wsl -l -q | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
if ($distroName -notin $wslDistros) {
    Write-Host "❌ WSL distribution $distroName is not installed. use .\wsl\00_quick_start.ps1"
    Write-Host "Available distributions: $($wslDistros -join ', ')" -ForegroundColor Gray
    exit 1
}

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
