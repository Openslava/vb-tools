# VB-Tools 🛠️

Automation tools for Windows development: WSL, WebLogic, Ansible.

## 🚀 Quick Start

```powershell
# Complete setup (WSL + WebLogic + Ansible)
.\00_quick_start.ps1

# Individual components
.\wsl\00_quick_start.ps1      # WSL only
.\ansible\00_quick_start.ps1  # Ansible only
.\weblogic\00_quick_start.ps1 # WebLogic
```

## 📁 Components

- **[WSL](./wsl/readme.md)** - Windows Subsystem for Linux setup
- **[WebLogic](./weblogic/readme.md)** - Oracle WebLogic automation  
- **[Ansible](./ansible/readme.md)** - Infrastructure automation

## 📋 Examples

```powershell
# Force password reset
.\weblogic\00_quick_start.ps1 -forse
```

```bash
# Build sample app
cd weblogic/sample && mvn clean package
```

## � License

MIT License - see [LICENSE](LICENSE)
