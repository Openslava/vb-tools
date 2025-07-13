# Script Descriptions

## 01_set_wsl.ps1

This PowerShell script checks if WSL (Windows Subsystem for Linux) is installed, installs a specified Linux distribution if it’s missing, and optionally sets it as the default. It then gathers DNS server addresses from Windows and runs a DNS setup script inside WSL to configure DNS settings for the Linux environment.

## 02_set_dns.sh

This shell script is executed inside WSL. It updates the WSL Linux distribution’s DNS configuration by replacing the `resolv.conf` file with the provided DNS server addresses, ensuring proper network resolution within WSL.