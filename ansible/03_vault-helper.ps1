<#
.SYNOPSIS
    Ansible Vault operations helper for Windows/WSL
.PARAMETER Action
    Vault action: create, edit, view, encrypt, decrypt, rekey, help
.PARAMETER VaultFile
    Vault file to operate on
.PARAMETER VaultPasswordFile
    Password file path
.PARAMETER Force
    Force operation without confirmation
#>
param(
    [Parameter(Position=0)]
    [ValidateSet("create", "edit", "view", "encrypt", "decrypt", "rekey", "help")]
    [string]$Action = "help",
    
    [Parameter(Position=1)]
    [string]$VaultFile = "",
    
    [string]$VaultPasswordFile = "",
    [switch]$Force
)

function Show-Help {
    Write-Host "- Ansible Vault Helper" -ForegroundColor Cyan
    Write-Host "Usage: .\vault-helper.ps1 <action> <vault-file> [options]" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Actions:" -ForegroundColor Green
    Write-Host "  create <file>  - Create encrypted vault file"
    Write-Host "  edit <file>    - Edit vault file"
    Write-Host "  view <file>    - View vault contents"
    Write-Host "  encrypt <file> - Encrypt plain text file"
    Write-Host "  decrypt <file> - Decrypt vault file"
    Write-Host "  rekey <file>   - Change vault password"
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Yellow
    Write-Host "  .\vault-helper.ps1 create secrets.yml"
    Write-Host "  .\vault-helper.ps1 edit group_vars/all/vault.yml"
    Write-Host "  .\vault-helper.ps1 view secrets.yml -VaultPasswordFile .vault_pass"
}

function Test-Ansible {
    wsl -e bash -c "which ansible-vault" 2>$null | Out-Null
    return ($LASTEXITCODE -eq 0)
}

function Invoke-Vault {
    param([string]$Command)
    
    if (-not (Test-Ansible)) {
        Write-Error "[ERROR] Ansible not found in WSL. Run: .\00_quick_start.ps1"
        exit 1
    }
    
    # Convert Windows path to WSL
    $wslFile = ""
    if ($VaultFile) {
        $wslFile = $VaultFile -replace '^([A-Za-z]):', '/mnt/$1' -replace '\\', '/'
        $wslFile = $wslFile.ToLower()
    }
    
    # Build command
    $cmd = "ansible-vault $Command"
    if ($wslFile) { $cmd += " '$wslFile'" }
    
    if ($VaultPasswordFile) {
        $wslPass = $VaultPasswordFile -replace '^([A-Za-z]):', '/mnt/$1' -replace '\\', '/'
        $cmd += " --vault-password-file '$($wslPass.ToLower())'"
    }
    
    Write-Host "- $cmd" -ForegroundColor Cyan
    wsl -e bash -c $cmd
}

# Main logic
if ($Action -eq "help" -or (-not $VaultFile -and $Action -ne "help")) {
    Show-Help
    exit 0
}

# File validation
if ($Action -in @("edit", "view", "decrypt", "rekey") -and -not (Test-Path $VaultFile)) {
    Write-Error "[ERROR] File not found: $VaultFile"
    exit 1
}

if ($Action -eq "create" -and (Test-Path $VaultFile) -and -not $Force) {
    Write-Error "[ERROR] File exists: $VaultFile (use -Force to overwrite)"
    exit 1
}

Write-Host "- $Action`: $VaultFile" -ForegroundColor Green
Invoke-Vault $Action
