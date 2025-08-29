
# Individual components

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

& "$scriptDir\wsl\00_quick_start.ps1"      # WSL only
& "$scriptDir\ansible\00_quick_start.ps1"  # Ansible only
& "$scriptDir\weblogic\00_quick_start.ps1" # WebLogic