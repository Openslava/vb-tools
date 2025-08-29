#!/bin/bash
# Install VS Code Portable on Windows via Ansible
set -e

PORTABLE_DIR="${1:-C:\\Tools\\VSCode-Portable}"
PLAYBOOK="$(dirname "$0")/install-vscode-portable-wsl.yml"

echo "Installing VS Code Portable to $PORTABLE_DIR"

# Check dependencies
if ! command -v ansible-playbook >/dev/null; then
    echo "[ERROR] Ansible not found. Install: sudo pip install ansible"
    exit 1
fi

if [ ! -f "$PLAYBOOK" ]; then
    echo "[ERROR] Playbook not found: $PLAYBOOK"
    exit 1
fi

# Run playbook
ansible-playbook "$PLAYBOOK" -e "vscode_portable_dir=/mnt/c/Tools/VSCode-Portable" -v

echo "[OK] Installation completed!"
echo "- Start: /mnt/c/Tools/VSCode-Portable/Code.exe"
