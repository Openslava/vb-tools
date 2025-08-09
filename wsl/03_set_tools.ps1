# installation of additional packages in WSL
[CmdletBinding()]
param(
    [string]$distroName = "OracleLinux_8_10",
    [switch]$forse
)

$commands = @(
    # Ensure script fails on error
    "set -e",
    "yum update -y",
    "yum install -y maven"
)

$script = $commands -join "`n"

# run script in WSL as root (Oracle Linux WSL may not have sudo by default)
Write-Host "Executing setup tools for $distroName distribution..."
wsl -d $distroName -u root -- bash -c "$script"
