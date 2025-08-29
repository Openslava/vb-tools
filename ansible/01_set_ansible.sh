#!/bin/bash
# Install Ansible on Oracle Linux/WSL
set -e

echo "### 01_set_ansible.sh -  Installing Ansible..."

# Check root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Must run as root"
    exit 1
fi

# Check if already installed (unless forced)
if command -v ansible >/dev/null 2>&1 && [ "$FORCE_MODE" != "true" ]; then
    echo "✅ Ansible already installed: $(ansible --version | head -1)"
    exit 0
fi

# Install dependencies
echo "📦 Installing dependencies..."
dnf update -y
dnf install -y python39 python39-pip python39-devel gcc git

# Setup Python alternatives
alternatives --install /usr/bin/python3 python3 /usr/bin/python3.9 1
alternatives --install /usr/bin/pip3 pip3 /usr/bin/pip3.9 1

# Install Ansible
echo "📤 Installing Ansible..."
python3.9 -m pip install --upgrade pip
if [ "$FORCE_MODE" = "true" ]; then
    python3.9 -m pip install --upgrade --force-reinstall ansible
else
    python3.9 -m pip install ansible
fi

# Install common collections
echo "📋 Installing collections..."
ansible-galaxy collection install community.general ansible.posix

# Create basic config
mkdir -p /etc/ansible
cat > /etc/ansible/ansible.cfg << 'EOF'
[defaults]
inventory = /etc/ansible/hosts
host_key_checking = False
interpreter_python = /usr/bin/python3.9
stdout_callback = yaml
EOF

cat > /etc/ansible/hosts << 'EOF'
[local]
localhost ansible_connection=local
EOF

echo "✅ Ansible installed: $(ansible --version | head -1)"
echo "🧪 Test: ansible localhost -m ping"
