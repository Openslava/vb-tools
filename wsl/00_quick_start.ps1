# Get the directory where this script is located
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# selected distribution name
$distroName = "OracleLinux_8_10"

# List current WSL distributions
# Manually Check WSL status
wsl -l -v

# Uninstall existing WSL distributions (if needed)
# wsl --unregister Ubuntu-22.04
# wsl --unregister OracleLinux_8_10

# Install and configure OracleLinux_8_10 WSL distribution and make it default
# during execution first will be requested to set the default WSL user / password, in second step use this credentials to do sudo 
& "$scriptDir\01_set_wsl.ps1" -distroName $distroName -setdefault

# Manually configure DNS (if needed)
# wsl -d $distroName -e sudo bash "$scriptDir\02_set_dns.sh" --dns "192.168.1.1,8.8.8.8"
