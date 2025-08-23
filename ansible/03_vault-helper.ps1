# PowerShell Script for Ansible Vault Operations
# Demonstrates how to use Ansible Vault from Windows PowerShell with WSL

param(
    [Parameter(Position=0)]
    [ValidateSet("create", "edit", "view", "encrypt", "decrypt", "rekey", "help")]
    [string]$Action = "help",
    
    [Parameter(Position=1)]
    [string]$VaultFile = "",
    
    [string]$VaultPasswordFile = "",
    [switch]$Force
)

# Colors for output
function Write-ColorText {
    param([string]$Text, [string]$Color = "White")
    switch ($Color) {
        "Green" { Write-Host $Text -ForegroundColor Green }
        "Yellow" { Write-Host $Text -ForegroundColor Yellow }
        "Red" { Write-Host $Text -ForegroundColor Red }
        "Cyan" { Write-Host $Text -ForegroundColor Cyan }
        default { Write-Host $Text }
    }
}

function Show-Help {
    Write-ColorText "Ansible Vault Helper for Windows" "Cyan"
    Write-ColorText "===============================" "Cyan"
    Write-Host ""
    Write-ColorText "Usage: .\vault-helper.ps1 <action> <vault-file> [options]" "Yellow"
    Write-Host ""
    Write-ColorText "Actions:" "Green"
    Write-Host "  create <file>     - Create new encrypted vault file"
    Write-Host "  edit <file>       - Edit existing vault file"
    Write-Host "  view <file>       - View vault file contents"
    Write-Host "  encrypt <file>    - Encrypt existing plain text file"
    Write-Host "  decrypt <file>    - Decrypt vault file to plain text"
    Write-Host "  rekey <file>      - Change vault password"
    Write-Host "  help              - Show this help"
    Write-Host ""
    Write-ColorText "Options:" "Green"
    Write-Host "  -VaultPasswordFile <path>  - Use password file instead of prompt"
    Write-Host "  -Force                     - Force operation without confirmation"
    Write-Host ""
    Write-ColorText "Examples:" "Yellow"
    Write-Host "  .\vault-helper.ps1 create secrets.yml"
    Write-Host "  .\vault-helper.ps1 edit group_vars/all/vault.yml"
    Write-Host "  .\vault-helper.ps1 view secrets.yml -VaultPasswordFile .vault_pass"
    Write-Host ""
    Write-ColorText "Note: Requires WSL with Ansible installed" "Yellow"
}

function Test-WSLAnsible {
    try {
        $result = wsl -e bash -c "which ansible-vault" 2>$null
        if ($LASTEXITCODE -eq 0) {
            return $true
        }
    }
    catch {
        return $false
    }
    return $false
}

function Invoke-VaultCommand {
    param([string]$Command)
    
    if (-not (Test-WSLAnsible)) {
        Write-ColorText "ERROR: Ansible not found in WSL. Please run ansible setup first:" "Red"
        Write-ColorText "  .\00_quick_start.ps1" "Yellow"
        exit 1
    }
    
    # Convert Windows path to WSL path if needed
    if ($VaultFile -match "^[A-Za-z]:") {
        $wslPath = $VaultFile -replace "^([A-Za-z]):", '/mnt/$1' -replace "\\", "/"
        $wslPath = $wslPath.ToLower()
    } else {
        $wslPath = $VaultFile
    }
    
    # Build command
    $vaultCmd = "ansible-vault $Command"
    if ($VaultFile) {
        $vaultCmd += " '$wslPath'"
    }
    
    if ($VaultPasswordFile) {
        if ($VaultPasswordFile -match "^[A-Za-z]:") {
            $wslPassPath = $VaultPasswordFile -replace "^([A-Za-z]):", '/mnt/$1' -replace "\\", "/"
            $wslPassPath = $wslPassPath.ToLower()
        } else {
            $wslPassPath = $VaultPasswordFile
        }
        $vaultCmd += " --vault-password-file '$wslPassPath'"
    }
    
    Write-ColorText "Executing: $vaultCmd" "Cyan"
    wsl -e bash -c $vaultCmd
}

# Main execution
switch ($Action) {
    "create" {
        if (-not $VaultFile) {
            Write-ColorText "ERROR: Vault file name required for create action" "Red"
            Write-ColorText "Usage: .\vault-helper.ps1 create <vault-file>" "Yellow"
            exit 1
        }
        
        if ((Test-Path $VaultFile) -and -not $Force) {
            Write-ColorText "ERROR: File '$VaultFile' already exists. Use -Force to overwrite." "Red"
            exit 1
        }
        
        Write-ColorText "Creating new vault file: $VaultFile" "Green"
        Write-ColorText "You will be prompted for a vault password..." "Yellow"
        Invoke-VaultCommand "create"
    }
    
    "edit" {
        if (-not $VaultFile) {
            Write-ColorText "ERROR: Vault file name required for edit action" "Red"
            exit 1
        }
        
        if (-not (Test-Path $VaultFile)) {
            Write-ColorText "ERROR: Vault file '$VaultFile' not found" "Red"
            exit 1
        }
        
        Write-ColorText "Editing vault file: $VaultFile" "Green"
        Invoke-VaultCommand "edit"
    }
    
    "view" {
        if (-not $VaultFile) {
            Write-ColorText "ERROR: Vault file name required for view action" "Red"
            exit 1
        }
        
        if (-not (Test-Path $VaultFile)) {
            Write-ColorText "ERROR: Vault file '$VaultFile' not found" "Red"
            exit 1
        }
        
        Write-ColorText "Viewing vault file: $VaultFile" "Green"
        Invoke-VaultCommand "view"
    }
    
    "encrypt" {
        if (-not $VaultFile) {
            Write-ColorText "ERROR: File name required for encrypt action" "Red"
            exit 1
        }
        
        if (-not (Test-Path $VaultFile)) {
            Write-ColorText "ERROR: File '$VaultFile' not found" "Red"
            exit 1
        }
        
        Write-ColorText "Encrypting file: $VaultFile" "Green"
        Write-ColorText "WARNING: This will modify the original file!" "Yellow"
        if (-not $Force) {
            $confirm = Read-Host "Continue? (y/N)"
            if ($confirm -ne "y" -and $confirm -ne "Y") {
                Write-ColorText "Operation cancelled" "Yellow"
                exit 0
            }
        }
        Invoke-VaultCommand "encrypt"
    }
    
    "decrypt" {
        if (-not $VaultFile) {
            Write-ColorText "ERROR: Vault file name required for decrypt action" "Red"
            exit 1
        }
        
        if (-not (Test-Path $VaultFile)) {
            Write-ColorText "ERROR: Vault file '$VaultFile' not found" "Red"
            exit 1
        }
        
        Write-ColorText "Decrypting vault file: $VaultFile" "Green"
        Write-ColorText "WARNING: This will save the file in plain text!" "Red"
        if (-not $Force) {
            $confirm = Read-Host "Continue? (y/N)"
            if ($confirm -ne "y" -and $confirm -ne "Y") {
                Write-ColorText "Operation cancelled" "Yellow"
                exit 0
            }
        }
        Invoke-VaultCommand "decrypt"
    }
    
    "rekey" {
        if (-not $VaultFile) {
            Write-ColorText "ERROR: Vault file name required for rekey action" "Red"
            exit 1
        }
        
        if (-not (Test-Path $VaultFile)) {
            Write-ColorText "ERROR: Vault file '$VaultFile' not found" "Red"
            exit 1
        }
        
        Write-ColorText "Changing vault password for: $VaultFile" "Green"
        Invoke-VaultCommand "rekey"
    }
    
    "help" {
        Show-Help
    }
    
    default {
        Write-ColorText "ERROR: Unknown action '$Action'" "Red"
        Show-Help
        exit 1
    }
}
