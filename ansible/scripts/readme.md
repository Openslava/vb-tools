# Ansible Example Scripts

This directory contains example scripts used by Ansible playbooks.

## Scripts

- `system-info.sh` - Simple system information gathering script
  - Used by: `../playbooks/execute-script.yml`
  - Usage: `./system-info.sh [--env environment]`
  - Purpose: Demonstrates remote script execution via Ansible

- `install-vscode-portable.sh` - Install VS Code Portable on Windows host
  - Used by: Standalone script that calls `../playbooks/install-vscode-portable-wsl.yml`
  - Usage: `./install-vscode-portable.sh [target_directory]`
  - Purpose: Demonstrates WSL-to-Windows host software installation
