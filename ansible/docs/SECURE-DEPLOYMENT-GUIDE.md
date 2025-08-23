# Secure Project-Based Ansible Deployment Guide

## 🎯 Problem Statement
- Store generic Ansible playbooks in **public GitHub repository**
- Keep VM lists and credentials **project-specific and private**
- Maintain security while enabling reusable automation

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│ PUBLIC REPOSITORY (github.com/youruser/vb-tools)           │
├─ ansible/                                                  │
│  ├─ playbooks/           # Generic, reusable playbooks     │
│  ├─ inventory-template.yml                                 │
│  ├─ group_vars/all.yml.template                           │
│  └─ deploy-project.sh.template                            │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ PRIVATE/LOCAL (NOT in GitHub)                              │
├─ project-configs/       # Project-specific configurations  │
│  ├─ project-a/                                            │
│  │  ├─ inventory.yml    # VM lists and connection details  │
│  │  ├─ group_vars/all.yml                                 │
│  │  ├─ .env            # Environment variables            │
│  │  └─ vault.yml       # Encrypted passwords (optional)   │
│  ├─ project-b/                                            │
│  └─ scripts/                                              │
│     ├─ deploy-project-a.sh                                │
│     └─ deploy-project-b.sh                                │
└─────────────────────────────────────────────────────────────┘
```

## 🔧 Implementation Steps

### 1. Setup Project Configuration (One-time per project)

```bash
# Clone the public repository
git clone https://github.com/youruser/vb-tools.git

# Create private project configuration (outside Git repository)
mkdir -p ../project-configs/my-production-project/{group_vars,host_vars}

# Copy templates and customize
cp vb-tools/ansible/inventory-template.yml ../project-configs/my-production-project/inventory.yml
cp vb-tools/ansible/group_vars/all.yml.template ../project-configs/my-production-project/group_vars/all.yml
cp vb-tools/ansible/deploy-project.sh.template ../project-configs/scripts/deploy-my-production.sh
```

### 2. Configure Project Secrets

#### Option A: Environment Variables (.env file)
```bash
# Create ../project-configs/my-production-project/.env
cat > ../project-configs/my-production-project/.env << 'EOF'
ANSIBLE_USER=deploy
ANSIBLE_BECOME_PASS=your_sudo_password
ANSIBLE_SSH_KEY=/home/user/.ssh/project_key
ANSIBLE_VAULT_PASS=vault_encryption_password
EOF

# Secure the file
chmod 600 ../project-configs/my-production-project/.env
```

#### Option B: Ansible Vault (Recommended for teams)
```bash
# Create encrypted vault file
cd ../project-configs/my-production-project
ansible-vault create vault.yml

# Add to vault.yml:
# vault_become_pass: "your_sudo_password"
# vault_ssh_key_path: "/path/to/ssh/key"

# Update group_vars/all.yml to use vault variables:
# ansible_become_pass: "{{ vault_become_pass }}"
```

### 3. Customize Inventory for Your VMs

Edit `../project-configs/my-production-project/inventory.yml`:

```yaml
all:
  vars:
    ansible_user: deploy
    ansible_ssh_private_key_file: "{{ lookup('env', 'ANSIBLE_SSH_KEY') }}"
    ansible_become_pass: "{{ lookup('env', 'ANSIBLE_BECOME_PASS') }}"
    
  children:
    production:
      children:
        webservers:
          hosts:
            web1.company.com:
              ansible_host: 10.0.1.10
            web2.company.com:
              ansible_host: 10.0.1.11
        databases:
          hosts:
            db1.company.com:
              ansible_host: 10.0.1.20
            db2.company.com:
              ansible_host: 10.0.1.21
              
    staging:
      children:
        webservers:
          hosts:
            staging-web.company.com:
              ansible_host: 10.0.2.10
```

### 4. Deploy Using Project Scripts

```bash
# Make script executable
chmod +x ../project-configs/scripts/deploy-my-production.sh

# Run operations
../project-configs/scripts/deploy-my-production.sh patch     # Patch all VMs
../project-configs/scripts/deploy-my-production.sh setup    # Setup systems
../project-configs/scripts/deploy-my-production.sh test     # Test connectivity
```

## 🔒 Security Best Practices

### 1. **Never Store Secrets in Git**
```bash
# Add to .gitignore in project-configs directory
echo "*.env" >> .gitignore
echo "vault.yml" >> .gitignore
echo "*.key" >> .gitignore
echo "*.pem" >> .gitignore
```

### 2. **Use Environment Variables for CI/CD**
```yaml
# GitHub Actions example
env:
  ANSIBLE_USER: ${{ secrets.ANSIBLE_USER }}
  ANSIBLE_BECOME_PASS: ${{ secrets.ANSIBLE_BECOME_PASS }}
  ANSIBLE_SSH_KEY: ${{ secrets.SSH_PRIVATE_KEY }}

steps:
  - name: Setup project config
    run: |
      mkdir -p project-configs/production
      echo "$ANSIBLE_SSH_KEY" > project-configs/production/ssh_key
      chmod 600 project-configs/production/ssh_key
```

### 3. **Vault Password Management**
```bash
# Store vault password in secure location
echo "vault_password" > ~/.ansible_vault_pass
chmod 600 ~/.ansible_vault_pass

# Use in ansible.cfg
echo "vault_password_file = ~/.ansible_vault_pass" >> ansible.cfg
```

### 4. **SSH Key Management**
```bash
# Generate project-specific SSH keys
ssh-keygen -t ed25519 -f ~/.ssh/project_production_key -C "ansible-production"

# Use in inventory
ansible_ssh_private_key_file: "~/.ssh/project_production_key"
```

## 🚀 Usage Examples

### Basic Operations
```bash
# Patch all production servers
../project-configs/scripts/deploy-production.sh patch

# Setup staging environment
../project-configs/scripts/deploy-staging.sh setup

# Run custom playbook
../project-configs/scripts/deploy-production.sh custom my-custom-playbook.yml
```

### Advanced Usage
```bash
# Run with specific target group
ansible-playbook -i ../project-configs/production/inventory.yml \
  vb-tools/ansible/playbooks/patch-systems.yml \
  --extra-vars "target_group=webservers"

# Run with vault
ansible-playbook -i ../project-configs/production/inventory.yml \
  vb-tools/ansible/playbooks/patch-systems.yml \
  --vault-password-file ~/.ansible_vault_pass
```

## 📁 Final Directory Structure

```
workspace/
├── vb-tools/                    # Public Git repository
│   └── ansible/
│       ├── playbooks/           # Generic playbooks
│       ├── inventory-template.yml
│       └── *.template files
│
├── project-configs/             # Private, not in Git
│   ├── production-web/
│   │   ├── inventory.yml        # Production VMs
│   │   ├── group_vars/all.yml
│   │   ├── .env                 # Secrets
│   │   └── vault.yml            # Encrypted secrets
│   ├── staging-app/
│   │   ├── inventory.yml        # Staging VMs  
│   │   └── .env
│   └── scripts/
│       ├── deploy-production.sh
│       └── deploy-staging.sh
│
└── .ssh/
    ├── production_key           # Project SSH keys
    └── staging_key
```

## ✅ Benefits

1. **🔓 Public Playbooks**: Shareable, version-controlled automation
2. **🔒 Private Configs**: Secure, project-specific credentials and VM lists
3. **🔄 Reusable**: Same playbooks work across multiple projects
4. **👥 Team-Friendly**: Each team member can have their own project configs
5. **🏭 CI/CD Ready**: Easy integration with deployment pipelines
6. **📦 Modular**: Add new projects without changing existing ones

This approach gives you the best of both worlds: reusable automation in public repositories and secure, project-specific configurations kept private.
