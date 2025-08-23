#!/bin/bash
set -e

# Ansible Installation Script for Oracle Linux/WSL
# This script installs Ansible and related tools
echo "01_set_ansible.sh - Starting Ansible Installation"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root or with sudo"
    exit 1
fi

# Check if force mode is enabled
if [ "$FORCE_MODE" = "true" ]; then
    echo "Force mode enabled - will reinstall Ansible"
    FORCE_INSTALL=true
else
    FORCE_INSTALL=false
fi

# Check if Ansible is already installed (idempotent)
if command -v ansible >/dev/null 2>&1 && [ "$FORCE_INSTALL" = "false" ]; then
    echo "Ansible is already installed:"
    ansible --version
    echo "Skipping installation. Use -forse to reinstall."
    exit 0
fi

echo "Installing Ansible on Oracle Linux..."

# Update system packages
echo "Updating system packages..."
dnf update -y

# Install Python and pip if not present
echo "Installing Python and development tools..."
dnf install -y python39 python39-pip python39-devel gcc openssl-devel libffi-devel

# Create symbolic links for python3.9 if needed
if ! command -v python3.9 >/dev/null 2>&1; then
    echo "Error: Python 3.9 installation failed"
    exit 1
fi

# Update alternatives to use Python 3.9 as default python3
alternatives --install /usr/bin/python3 python3 /usr/bin/python3.9 1
alternatives --install /usr/bin/pip3 pip3 /usr/bin/pip3.9 1

# Install additional packages needed for Ansible
echo "Installing system dependencies..."
dnf install -y git curl wget which

# Create symbolic link for python if needed
if ! command -v python >/dev/null 2>&1; then
    echo "Creating python symlink..."
    ln -sf /usr/bin/python3.9 /usr/bin/python
fi

# Upgrade pip using Python 3.9
echo "Upgrading pip..."
python3.9 -m pip install --upgrade pip

# Install Ansible via pip (more current than dnf packages)
if [ "$FORCE_INSTALL" = "true" ]; then
    echo "Force installing Ansible..."
    python3.9 -m pip install --upgrade --force-reinstall ansible
else
    echo "Installing Ansible..."
    python3.9 -m pip install ansible
fi

# Install useful Ansible collections and tools
echo "Installing Ansible collections and tools..."
python3.9 -m pip install ansible-lint molecule[docker] jmespath

# Install common Ansible collections
echo "Installing Ansible collections..."
ansible-galaxy collection install community.general
ansible-galaxy collection install ansible.posix
ansible-galaxy collection install community.crypto

# Create ansible configuration directory
echo "Creating Ansible configuration..."
mkdir -p /etc/ansible
mkdir -p /home/ansible

# Create basic ansible.cfg if it doesn't exist
if [ ! -f /etc/ansible/ansible.cfg ]; then
    cat > /etc/ansible/ansible.cfg << 'EOF'
[defaults]
inventory = /etc/ansible/hosts
host_key_checking = False
timeout = 30
gathering = smart
fact_caching = memory
stdout_callback = yaml
callback_whitelist = timer, profile_tasks
deprecation_warnings = False
interpreter_python = /usr/bin/python3.9
become_method = su
become_ask_pass = False

[inventory]
enable_plugins = host_list, script, auto, yaml, ini, toml

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s
pipelining = True

[privilege_escalation]
become = True
become_method = su
become_user = root
become_ask_pass = False
# Uncomment and set if you need a password for su
# become_pass = your_password_here
EOF
fi

# Create basic inventory file if it doesn't exist
if [ ! -f /etc/ansible/hosts ]; then
    cat > /etc/ansible/hosts << 'EOF'
# Ansible inventory file
# Add your hosts here

[local]
localhost ansible_connection=local

[webservers]
# web1.example.com
# web2.example.com

[databases]
# db1.example.com
# db2.example.com
EOF
fi

# Create ansible user for running playbooks (optional)
if ! id "ansible" &>/dev/null; then
    echo "Creating ansible user..."
    useradd -m -s /bin/bash ansible
    echo "ansible ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ansible
fi

# Set permissions
chown -R ansible:ansible /home/ansible
chmod 755 /etc/ansible
chmod 644 /etc/ansible/ansible.cfg
chmod 644 /etc/ansible/hosts

# Verify installation
echo ""
echo "=== Ansible Installation Verification ==="
ansible --version
echo ""
echo "Available collections:"
ansible-galaxy collection list
echo ""
echo "=== Installation Complete ==="
echo "Configuration file: /etc/ansible/ansible.cfg"
echo "Inventory file: /etc/ansible/hosts"
echo "Ansible user created: ansible"
echo ""
echo "Basic commands:"
echo "  ansible --version"
echo "  ansible localhost -m ping"
echo "  ansible-playbook playbook.yml"
echo "  ansible-galaxy collection install <collection>"
echo ""
echo "To switch to ansible user: su - ansible"
