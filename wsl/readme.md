# WSL Scripts

This directory contains scripts for setting up and configuring Windows Subsystem for Linux (WSL) environment.

## Quick Start

```powershell
# Navigate to the WSL scripts directory
cd .\wsl\

# List current WSL distributions
wsl -l -v

# Uninstall existing WSL distributions (if needed)
wsl --unregister Ubuntu-22.04
wsl --unregister OracleLinux_8_10

# Install and configure OracleLinux_8_10 WSL distribution
.\01_set_wsl.ps1

# Install Ubuntu-22.04 Linux WSL distribution and set as default
.\01_set_wsl.ps1 -distroName "Ubuntu-22.04" -setdefault

# Manually configure DNS (if needed)
wsl -d OracleLinux_8_10 -e sudo bash .\02_set_dns.sh --dns "192.168.1.1,8.8.8.8"

# Check WSL status
wsl -l -v
wsl -d OracleLinux_8_10 -e cat /etc/resolv.conf
```


## 01_set_wsl.ps1

PowerShell script that automates WSL setup and configuration.

**Features:**

- Checks if WSL is installed on the system
- Installs specified Linux distribution if not present (supports Ubuntu-22.04 and OracleLinux_8_10)
- Optionally sets the distribution as default WSL distro
- Automatically configures DNS settings for the WSL environment

**Parameters:**

- `-distroName` - Linux distribution to install (default: "Ubuntu-22.04")
- `-setdefault` - Switch to set the distribution as default

**Usage:**

```powershell
# Install Ubuntu-22.04 (default)
.\01_set_wsl.ps1

# Install Oracle Linux and set as default
.\01_set_wsl.ps1 -distroName "OracleLinux_8_10" -setdefault
```

**What it does:**

1. Verifies WSL is installed
2. Installs the specified Linux distribution if missing
3. Collects DNS server addresses from Windows network configuration
4. Runs DNS configuration script inside WSL with collected DNS servers
5. Falls back to public DNS (8.8.8.8, 1.1.1.1) if no DNS servers found

## 02_set_dns.sh

Bash script that configures DNS settings within WSL Linux environment.

**Features:**

- Backs up existing DNS configuration
- Disables automatic DNS generation by WSL
- Configures custom DNS servers for proper network resolution

**Usage:**

```bash
# Called automatically by 01_set_wsl.ps1
sudo bash 02_set_dns.sh --dns "192.168.1.1,8.8.8.8"

# Use default DNS servers only
sudo bash 02_set_dns.sh
```

**What it does:**

1. Creates backup of current `/etc/resolv.conf`
2. Configures WSL to not auto-generate DNS configuration
3. Removes existing DNS configuration
4. Writes new DNS servers to `/etc/resolv.conf`
5. Includes fallback DNS servers (8.8.8.8, 1.1.1.1)

## 03_set_tools.ps1

PowerShell script for installing additional tools and utilities in WSL environment.

**Status:** Currently empty - placeholder for future tool installation functionality.
