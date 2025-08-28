<#
.SYNOPSIS
    Quick WebLogic setup for WSL
.PARAMETER distroName
    WSL distribution name (default: "OracleLinux_8_10")
.PARAMETER domainName
    WebLogic domain name (default: "test_domain")
.PARAMETER adminUser
    Admin username (default: "admin")
.PARAMETER adminPassword
    Admin password (default: "testpwd1")
.PARAMETER adminPort
    Admin port (default: 7001)
.PARAMETER force
    Forces recreation of domain
.NOTES
    Prerequisites: Download JDK 8 and WebLogic 12c to ~/Downloads/
#>
[CmdletBinding()]
param(
    [string]$distroName = "OracleLinux_8_10",
    [string]$domainName = "test_domain", 
    [string]$adminUser = "admin",
    [string]$adminPassword = "testpwd1",
    [int]$adminPort = 7001,
    [switch]$force
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$repoRoot = Split-Path -Parent $scriptDir

Write-Host "### 00_quick_start.ps1 - Setting up WebLogic on $distroName" -ForegroundColor Cyan
Write-Host " Domain: $domainName | Port: $adminPort | User: $adminUser" -ForegroundColor Yellow

# Check required Oracle files
$downloadsPath = "$env:USERPROFILE\Downloads"
$jdkFile = "$downloadsPath\jdk-8u461-linux-x64.rpm"
$weblogicFile = "$downloadsPath\fmw_12.2.1.4.0_infrastructure_Disk1_1of1.zip"

if (!(Test-Path $jdkFile) -or !(Test-Path $weblogicFile)) {
    Write-Host "❌ Required Oracle files missing in Downloads folder:" -ForegroundColor Red
    if (!(Test-Path $jdkFile)) { Write-Host "   Missing: jdk-8u461-linux-x64.rpm" -ForegroundColor Yellow }
    if (!(Test-Path $weblogicFile)) { Write-Host "   Missing: fmw_12.2.1.4.0_infrastructure_Disk1_1of1.zip" -ForegroundColor Yellow }
    Write-Host "📥 Download from:" -ForegroundColor Cyan
    Write-Host "   Oracle JDK 8u461: https://www.oracle.com/java/technologies/javase-jdk8-doc-downloads.html" -ForegroundColor White
    Write-Host "   WebLogic 12.2.1.4.0: https://www.oracle.com/qa/middleware/technologies/weblogic-server-downloads.html" -ForegroundColor White
    exit 1
}

Write-Host "✅ Required Oracle files found" -ForegroundColor Green

# Setup WSL first
& "$repoRoot\wsl\01_set_wsl.ps1" -distroName $distroName -force:$force

# Install WebLogic
$wslRepoRoot = (wsl -d $distroName -e wslpath "$repoRoot").Trim()
$wsljdkFile = (wsl -d $distroName -e wslpath "$jdkFile").Trim()
$wslweblogicFile = (wsl -d $distroName -e wslpath "$weblogicFile").Trim()

$script = @"
#!/bin/bash
set -e
cd '$wslRepoRoot'
mkdir -p /opt/oracle/install_files
cp -v $wsljdkFile /opt/oracle/install_files/
cp -v $wslweblogicFile /opt/oracle/install_files/
chmod 644 /opt/oracle/install_files/*
export DOMAIN_NAME='$domainName'
export ADMIN_USER='$adminUser'
export PORT=$adminPort
export ADMIN_PASSWORD='$adminPassword'
$(if ($force) { "export FORCE_MODE=true" } else { "export FORCE_MODE=false" })
./weblogic/01_set_weblogic.sh
./weblogic/02_set_domain.sh '$domainName'
./weblogic/03_start_domain.sh '$domainName'
"@

$script = $script -replace "`r`n", "`n"

wsl -d $distroName -u root -- bash -c "$script"

Write-Host "✅ WebLogic setup complete!" -ForegroundColor Green
Write-Host "🌐 Admin Console: http://localhost:$adminPort/console" -ForegroundColor Yellow
Write-Host "👤 User: $adminUser | Pass: $adminPassword" -ForegroundColor Yellow
