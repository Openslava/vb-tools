# WSL Scripts

Scripts for setting up and configuring Windows Subsystem for Linux (WSL) environment.

## Quick Start

### One-Command Setup

```powershell
# Complete WSL setup with Oracle Linux (installs if missing)
.\00_quick_start.ps1
```

### Custom Setup

```powershell
# Detect-only (no install), set as default
.\01_set_wsl.ps1 -distroName "OracleLinux_8_10" -setdefault

# Install if missing and set default
.\01_set_wsl.ps1 -distroName "OracleLinux_8_10" -setdefault
```

```powershell
# Unregister WSL distribution / removes from local host
wsl --unregister "OracleLinux_8_10"
```

### What Happens

1. **WSL Installation** - Installs chosen Linux distribution when -install is used (detect-only by default)
2. **DNS Configuration** - Auto-configures DNS for network connectivity  
3. **Password Setup** - You'll set username/password for WSL (remember for sudo)

### Result

- Ready-to-use WSL environment
- Proper DNS resolution
- Access via: `wsl -d OracleLinux_8_10`

## Scripts

- **00_quick_start.ps1** - Complete automated setup
- **01_set_wsl.ps1** - WSL distribution detection, optional installation (-install), default selection, and DNS configuration
- **02_set_dns.sh** - DNS configuration (invoked as root inside WSL)
- **03_set_tools.ps1** - Additional tools (placeholder)
