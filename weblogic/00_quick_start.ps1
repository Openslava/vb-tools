# !!! executed from the root of the repository

# !! Prerequisites - Manual Download from Oracle  JDK1.8... and WebLogic 12... !!
# URL: https://www.oracle.com/qa/middleware/technologies/weblogic-server-downloads.html  
# URL: https://www.oracle.com/java/technologies/javase-jdk8-doc-downloads.html

# Get the directory where this script is located and navigate to repository root
# Configuration with defaults (can be overridden)
[CmdletBinding()]
param(
    [string]$distroName = "OracleLinux_8_10",
    [string]$domainName = "test_domain",
    [string]$adminUser = "admin",
    [string]$adminPassword = "testpwd1",  # Empty means auto-generate
    [int]$adminPort = 7001,
    [switch]$forse
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$repoRoot = Split-Path -Parent $scriptDir

Write-Host "=== WebLogic Quick Setup ==="
Write-Host "WSL Distribution: $distroName"
Write-Host "WebLogic Domain: $domainName"
Write-Host "WebLogic Admin User: $adminUser"
Write-Host "WebLogic Admin Port: $adminPort"
Write-Host "WebLogic Admin Password: $adminPassword"
if ($forse) { Write-Host "Force mode: ENABLED (will recreate domain and update password)" }
Write-Host ""

# ensure WSL is setup  
Write-Host "Checking WSL distribution: $distroName"
& "$repoRoot\wsl\01_set_wsl.ps1" -distroName $distroName -forse:$forse

# Fix line endings in all bash scripts
Write-Host "Converting WebLogic script line endings..."
$wslRepoRoot = (wsl -d $distroName -e wslpath "$repoRoot").Trim()
wsl -d $distroName -u root -- bash -c "sed -i 's/\r$//' '$wslRepoRoot/weblogic/'*.sh"

Write-Host "Starting WebLogic installation..."

#  join them with LF line endings to be prepared for Linux
# Resolve repo root path inside WSL to ensure relative script paths work
$wslRepoRoot = (wsl -d $distroName -e wslpath "$repoRoot").Trim()
$commands = @(
    # Ensure script fails on error
    "set -e",
    # work from repo root so relative paths resolve
    "cd '$wslRepoRoot'",
    # create install directory
    "pwd",
    "mkdir -p /opt/oracle/install_files",
    # Copy files to WSL and install weblogic from host Downloads folder,
    "cp -v /mnt/c/Users/$env:USERNAME/Downloads/jdk-8u461-linux-x64.rpm /opt/oracle/install_files/",
    "cp -v /mnt/c/Users/$env:USERNAME/Downloads/fmw_12.2.1.4.0_infrastructure_Disk1_1of1.zip /opt/oracle/install_files/",
    # set safe permissions after files are present
    "chmod 644 /opt/oracle/install_files/*",
    "ls -la /opt/oracle/install_files/",
    # WebLogic domain configuration
    "export DOMAIN_NAME='$domainName'",
    "export ADMIN_USER='$adminUser'",
    "export PORT=$adminPort",
    "export ADMIN_PASSWORD='$adminPassword'",
    $(if ($forse) { "export FORCE_MODE=true" } else { "export FORCE_MODE=false" }),
    # Navigate to weblogic scripts directory and run as root, then switch to weblogic user
    "./weblogic/01_set_weblogic.sh",
    "./weblogic/02_set_domain.sh '$domainName'"
)

$script = $commands -join "`n"

# run script in WSL as root (Oracle Linux WSL may not have sudo by default)
Write-Host "Executing WebLogic setup in WSL..."
wsl -d $distroName -u root -- bash -c "$script"

Write-Host ""
Write-Host "=== WebLogic Setup Complete ==="
Write-Host "Admin Console: http://localhost:$adminPort/console"
Write-Host "Username: $adminUser"
Write-Host "Password: $adminPassword"
Write-Host ""
Write-Host "Domain: $domainName"
Write-Host "Access WSL: wsl -d $distroName"

