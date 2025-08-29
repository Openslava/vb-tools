<#
.SYNOPSIS
    Update WSL and install tools
.PARAMETER distroName
    WSL distribution name (default: "OracleLinux_8_10")
.PARAMETER toolList
    Tools to install (default: maven,git,curl,wget,unzip,nano,vim)
.PARAMETER force
    Forces reinstallation
#>
[CmdletBinding()]
param(
    [ValidateSet("Ubuntu-22.04", "OracleLinux_8_10")]
    [string]$distroName = "OracleLinux_8_10",
    [string]$toolList = "maven,git,curl,wget,unzip,nano,vim",
    [switch]$force
)

Write-Host "### 03_set_update.ps1 - Updating $distroName and installing tools" -ForegroundColor Cyan

# Test if tools exist
function Test-Tools($distro, $tools) {
    $missing = @()
    foreach ($tool in $tools) {
        $exists = switch ($tool.ToLower()) {
            "maven" { wsl -d $distro -- mvn --version 2>$null; $LASTEXITCODE -eq 0 }
            "git" { wsl -d $distro -- git --version 2>$null; $LASTEXITCODE -eq 0 }
            default { wsl -d $distro -- which $tool 2>$null; $LASTEXITCODE -eq 0 }
        }
        if (-not $exists) { $missing += $tool }
    }
    return $missing
}

$tools = $toolList -split ',' | ForEach-Object { $_.Trim() }
$missing = Test-Tools $distroName $tools

if (-not $force -and $missing.Count -eq 0) {
    Write-Host "✅ All tools installed - no updates needed! Use -force to reinstall" -ForegroundColor Green
    exit 0
}

try {
    $isUbuntu = $distroName -match "Ubuntu"
    $updateCmd = if ($isUbuntu) { "apt-get update -y" } else { "yum update -y" }
    $installCmd = if ($isUbuntu) { "apt-get install -y" } else { "yum install -y" }
    
    # Map special packages
    $packages = foreach ($tool in $tools) {
        switch ($tool.ToLower()) {
            "nodejs" { if ($isUbuntu) { "nodejs", "npm" } else { "nodejs" } }
            "python3" { "python3", "python3-pip" }
            default { $tool }
        }
    }
    $packageList = ($packages | Select-Object -Unique) -join ' '
    
    Write-Host "- Installing: $packageList"

    wsl -d $distroName -u root -- bash -c "set -e; $updateCmd; $installCmd $packageList"

    # if failed then add "user_agent-curl/7.61.1" to /etc/yum.conf and try again
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[WARN] Installation failed, trying workaround..." -ForegroundColor Yellow
        # add mentioned line only if not present and only for yum
        if ($updateCmd -eq "yum update -y") {
            wsl -d $distroName -u root -- bash -c "grep -qxF 'user_agent-curl/7.61.1' /etc/yum.conf || echo 'user_agent-curl/7.61.1' >> /etc/yum.conf"
        }
        wsl -d $distroName -u root -- bash -c "set -e; $updateCmd; $installCmd $packageList"
    }

    $stillMissing = Test-Tools $distroName $tools
    if ($stillMissing.Count -eq 0) {
        Write-Host "[SUCCESS] All tools installed successfully!" -ForegroundColor Green
    } else {
        Write-Host "[WARN] Some tools still missing: $($stillMissing -join ', ')" -ForegroundColor Yellow
    }
} catch {
    Write-Error "[ERROR] Installation failed: $_"
    exit 1
}
