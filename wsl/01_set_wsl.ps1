<#
.SYNOPSIS
    Sets up WSL with specified Linux distribution
.PARAMETER distroName
    Linux distribution to install (default: "OracleLinux_8_10")
.PARAMETER setdefault
    Sets as default WSL distribution
.PARAMETER force
    Forces reinstallation
#>
[CmdletBinding()]
param (
    [ValidateSet("Ubuntu-22.04", "OracleLinux_8_10")]
    [string]$distroName = "OracleLinux_8_10",
    [switch]$setdefault,
    [switch]$force
)

Write-Host "### 01_set_wsl.ps1 - Setting up WSL with $distroName" -ForegroundColor Cyan

$wslScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Convert all sh files in subfolders to Unix line endings using PowerShell
Get-ChildItem -Path "$wslScriptDir" -Filter "*.sh" -Recurse | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    $content = $content -replace "`r`n", "`n"
    Set-Content $_.FullName -Value $content -NoNewline
}

# Check WSL availability
if (-not (Get-Command wsl -ErrorAction SilentlyContinue)) {
    Write-Error "❌ WSL not available. Enable WSL feature and reboot."
    exit 1
}

# Install if missing or forced
$installedDistros = wsl -l -q
if (-not ($installedDistros -contains $distroName) -or $force) {
    Write-Host "📦 Installing $distroName... (type 'exit' in first console to continue)"
    wsl --install -d $distroName
    wsl -d $distroName --shutdown
    Start-Sleep 5
} else {
    Write-Host "✅ $distroName already installed"
}

# Set as default
if ($setdefault) {
    wsl --set-default $distroName
    Write-Host "✅ Set $distroName as default"
}

# Convert all sh files in subfolders to Unix line endings using sed
Write-Host "🔄 Converting .sh files to Unix line endings..."
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$repoRoot = Split-Path -Parent $scriptDir
$wslRepoPath = (wsl -d $distroName -e wslpath "$repoRoot").Trim()

wsl -d $distroName -- bash -c "find '$wslRepoPath' -name '*.sh' -type f -exec sed -i 's/\r$//' {} \;"

wsl -l -v
