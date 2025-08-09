<#
.SYNOPSIS
    Quick setup script for Windows Subsystem for Linux (WSL) with Oracle Linux distribution.

.EXAMPLE
    .\00_quick_start.ps1
    Performs complete WSL setup with Oracle Linux 8.10 as default distribution.

.NOTES
    File Name      : 00_quick_start.ps1
    Author         : Viliam Batka
    Prerequisite   : Windows 10/11 with WSL feature available

    Uninstall existing WSL distributions (if needed)
    wsl --unregister OracleLinux_8_10
#>
[CmdletBinding()]
param(
    [string]$distroName = "OracleLinux_8_10",
    [switch]$forse
)

# Get the directory where this script is located
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Install (if missing) and configure the WSL distribution and make it default
# On first launch, Windows may prompt to create a UNIX username/password for the distro.
& "$scriptDir\01_set_wsl.ps1" -distroName $distroName -setdefault -forse:$forse

# List current WSL distributions
wsl -l -v
# end