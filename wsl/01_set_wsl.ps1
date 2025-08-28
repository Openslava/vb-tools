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

wsl -l -v
