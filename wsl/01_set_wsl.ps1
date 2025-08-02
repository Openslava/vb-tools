
# author: viliam batka
# This script checks for WSL installation, installs a specified Linux distribution if not present,
# and configures DNS settings within the WSL environment.
[CmdletBinding()]
param (
    [ValidateSet("Ubuntu-22.04", "OracleLinux_8_10")]
    [string]$distroName = "OracleLinux_8_10",
    [switch]$setdefault
)

if (-not (Get-Command wsl -ErrorAction SilentlyContinue)) {
    Write-Host "WSL is not installed. Please install WSL manually."
    exit 1
}

# Install distro if missing
if (-not (wsl -l -q | Where-Object { $_ -eq $distroName })) {
    wsl --install -d $distroName
}

# Set default if requested
if ($setdefault) { wsl --set-default $distroName }

# Get DNS servers, fallback if none
$dnsServers = (Get-DnsClientServerAddress -AddressFamily IPv4).ServerAddresses | Select-Object -Unique | Where-Object { $_ -match '^\d+\.\d+\.\d+\.\d+$' }
$dnsServers = $dnsServers -join ','
if (-not $dnsServers) { $dnsServers = '8.8.8.8,1.1.1.1' }

# Run DNS setup script in WSL
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$winScriptPath = Join-Path $scriptDir "02_set_dns.sh" | Resolve-Path
$wslScriptPath = wsl -d $distroName -e wslpath "$winScriptPath"
Write-Host "Setting up DNS for WSL (Windows Subsystem for Linux) by replacing the resolv.conf file..."
wsl -d $distroName -e sudo bash "$wslScriptPath" --dns "$dnsServers"

# End