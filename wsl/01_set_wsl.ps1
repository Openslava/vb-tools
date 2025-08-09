<#
.SYNOPSIS
    Sets up Windows Subsystem for Linux (WSL) with a specified Linux distribution and configures DNS settings.

.PARAMETER distroName
    Specifies the Linux distribution to install or configure.
    Default: "OracleLinux_8_10"

.PARAMETER setdefault
    Switch parameter. When specified, sets the configured distribution as the default WSL distribution.

.EXAMPLE
    .\01_set_wsl.ps1
    Installs OracleLinux_8_10 (if missing) and configures DNS settings.

.NOTES
    File Name      : 01_set_wsl.ps1
    Author         : Viliam Batka
    Prerequisite   : Windows 10/11 with WSL feature available    

.LINK
    https://docs.microsoft.com/en-us/windows/wsl/
#>

[CmdletBinding()]
param (
    [ValidateSet("Ubuntu-22.04", "OracleLinux_8_10")]
    [string]$distroName = "OracleLinux_8_10",
    [switch]$setdefault,
    [switch]$forse
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$repoRoot = Split-Path -Parent $scriptDir

# Resolve wsl.exe path (handles cases where 'wsl' isn't on PATH yet)
$wslCmd = (Get-Command wsl -ErrorAction SilentlyContinue)?.Source
if (-not $wslCmd) {
    Write-Warning "WSL is not available on this system. Use -install to enable required Windows features, then reboot."
    exit 1
}

# Detect distro; install if missing (non-interactive)
if (-not (& $wslCmd -l -q | Where-Object { $_ -eq $distroName }) -or $forse) {
    Write-Host "Start Installing WSL distribution: $distroName"
    Write-Host " - NOTE: type 'exit' into first WSL console after installing, to continue installation process ..."
    & $wslCmd --install -d $distroName 

    # Get DNS servers, fallback if none
    $dnsServers = (Get-DnsClientServerAddress -AddressFamily IPv4).ServerAddresses | Select-Object -Unique | Where-Object { $_ -match '^\d+\.\d+\.\d+\.\d+$' }
    $dnsServers = $dnsServers -join ','
    if (-not $dnsServers) { $dnsServers = '8.8.8.8,1.1.1.1' }

    # Run DNS setup script in WSL
    Write-Host "Converting WebLogic script line endings..."
    $wslRepoRoot = (& $wslCmd -d $distroName -e wslpath "$repoRoot").Trim()
    & $wslCmd -d $distroName -u root -- bash -c "sed -i 's/\r$//' '$wslRepoRoot/wsl/'*.sh"

    Write-Host "Setting up DNS in WSL distribution (Windows Subsystem for Linux) by replacing the resolv.conf file..."
    & $wslCmd -d $distroName -u root -- bash "$wslRepoRoot/wsl/02_set_dns.sh" --dns "$dnsServers"
    Write-Host "Restarting WSL to apply changes..."
    & $wslCmd --shutdown
} else {
    Write-Host "WSL distribution '$distroName' already installed"
}

# List current WSL distributions
wsl -l -v


# End