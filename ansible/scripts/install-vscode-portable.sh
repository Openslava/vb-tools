#!/bin/bash

# Script to install VS Code Portable on Windows host from WSL using Ansible
# Usage: ./install-vscode-portable.sh [portable_dir]

set -e

PORTABLE_DIR="${1:-C:\\Tools\\VSCode-Portable}"
PLAYBOOK_PATH="$(dirname "$0")/install-vscode-portable-wsl.yml"

echo "🚀 Installing VS Code Portable on Windows Host"
echo "📁 Target directory: $PORTABLE_DIR"
echo "📜 Using playbook: $PLAYBOOK_PATH"
echo ""

# Check if Ansible is available
if ! command -v ansible-playbook &> /dev/null; then
    echo "❌ Ansible not found. Please install Ansible first:"
    echo "   sudo pip install ansible"
    exit 1
fi

# Check if playbook exists
if [ ! -f "$PLAYBOOK_PATH" ]; then
    echo "❌ Playbook not found: $PLAYBOOK_PATH"
    exit 1
fi

# Run the playbook
echo "▶️ Running Ansible playbook..."
ansible-playbook "$PLAYBOOK_PATH" \
    -e "vscode_portable_dir=/mnt/c/Tools/VSCode-Portable" \
    -v

echo ""
echo "✅ Installation script completed!"
echo ""
echo "🔍 To verify installation:"
echo "   ls -la /mnt/c/Tools/VSCode-Portable/"
echo ""
echo "🚀 To start VS Code:"
echo "   /mnt/c/Tools/VSCode-Portable/Code.exe"
