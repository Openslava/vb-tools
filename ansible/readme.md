# Ansible Scripts

Scripts for installing and configuring Ansible on WSL/Oracle Linux environments.

## Quick Start

### One-Command Setup

```powershell
# Complete Ansible setup (installs WSL if missing)
.\00_quick_start.ps1
```

### Custom Setup

```powershell
# Use specific WSL distribution
.\00_quick_start.ps1 -distroName "OracleLinux_8_10"

# Force reinstall Ansible
.\00_quick_start.ps1 -forse
```

### What Happens

1. **WSL Setup** - Ensures WSL with Oracle Linux is available
2. **System Updates** - Updates packages and installs Python/pip
3. **Ansible Installation** - Installs latest Ansible via pip
4. **Configuration** - Creates basic ansible.cfg and inventory
5. **Collections** - Installs common Ansible collections
6. **User Setup** - Creates dedicated ansible user

### Result

- Ready-to-use Ansible environment
- Basic configuration files in `/etc/ansible/`
- Common collections pre-installed
- Dedicated ansible user for running playbooks

## Usage Examples

```bash
# Test local connection
ansible localhost -m ping

# Run ad-hoc command
ansible all -m setup

# Run playbook
ansible-playbook site.yml

# Install new collection
ansible-galaxy collection install community.docker
```

## Scripts

- **00_quick_start.ps1** - Complete automated setup
- **01_set_ansible.sh** - Ansible installation and configuration

## 📚 Documentation

- **[Playbooks](playbooks/README.md)** - 3 essential playbooks: patch-systems, setup-local-dev, execute-script
- **[Scripts](scripts/README.md)** - Example scripts for execute-script.yml
- **[Secure Deployment Guide](docs/SECURE-DEPLOYMENT-GUIDE.md)** - Public repo + private configs  
- **[Ansible Vault Guide](docs/ANSIBLE-VAULT-GUIDE.md)** - Password encryption tutorial
- **[Configuration Templates](docs/)** - Templates for inventory, variables, deployment scripts

## Configuration Files

- `/etc/ansible/ansible.cfg` - Main Ansible configuration
- `/etc/ansible/hosts` - Default inventory file
- `/home/ansible/` - Ansible user home directory


