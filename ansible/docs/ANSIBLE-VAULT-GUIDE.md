# Ansible Vault Guide - Complete Tutorial

## 🆓 Is Ansible Vault Free?

**YES! Ansible Vault is completely FREE.** It's a built-in feature of Ansible (which is also free and open-source). No licensing fees, no subscriptions needed.

## 🔧 What is Ansible Vault?

Ansible Vault encrypts sensitive data files (passwords, API keys, certificates) so you can store them safely in version control.

## 📋 Basic Vault Commands

### 1. Create a New Vault File
```bash
# Create new encrypted file (will prompt for password)
ansible-vault create secrets.yml

# Example content you'll add:
---
vault_database_password: "super_secret_db_password"
vault_api_key: "your_api_key_here"
vault_ssh_password: "your_ssh_password"
vault_become_pass: "your_sudo_password"
```

### 2. Edit Existing Vault File
```bash
# Edit encrypted file (will prompt for password)
ansible-vault edit secrets.yml
```

### 3. View Vault File Contents
```bash
# View without editing (will prompt for password)
ansible-vault view secrets.yml
```

### 4. Change Vault Password
```bash
# Change the encryption password
ansible-vault rekey secrets.yml
```

### 5. Encrypt Existing File
```bash
# Encrypt a plain text file
ansible-vault encrypt plain-secrets.yml
```

### 6. Decrypt File
```bash
# Decrypt to plain text (be careful!)
ansible-vault decrypt secrets.yml
```

## 🛠️ Practical Examples

### Example 1: Create Project Vault
```bash
# Step 1: Create vault file
ansible-vault create group_vars/all/vault.yml

# Step 2: Add this content when editor opens:
---
# Database credentials
vault_db_user: "app_user"
vault_db_password: "complex_db_password_123!"

# SSH and sudo credentials  
vault_ansible_user: "deploy"
vault_become_pass: "sudo_password_456!"

# API keys
vault_api_key: "abcd1234efgh5678ijkl"
vault_ssl_cert_password: "cert_password_789!"

# Step 3: Save and exit (will be encrypted automatically)
```

### Example 2: Use Vault Variables in Playbooks
```yaml
---
- name: Deploy application with vault secrets
  hosts: all
  become: true
  vars:
    # Reference vault variables
    ansible_become_pass: "{{ vault_become_pass }}"
    db_connection_string: "mysql://{{ vault_db_user }}:{{ vault_db_password }}@localhost/myapp"
    
  tasks:
    - name: Configure database connection
      template:
        src: app-config.j2
        dest: /etc/myapp/config.yml
      vars:
        api_key: "{{ vault_api_key }}"
        db_password: "{{ vault_db_password }}"
```

### Example 3: Multiple Vault Files
```bash
# Production secrets
ansible-vault create group_vars/production/vault.yml

# Staging secrets  
ansible-vault create group_vars/staging/vault.yml

# Development secrets
ansible-vault create group_vars/development/vault.yml
```

## 🔐 Running Playbooks with Vault

### Method 1: Interactive Password Prompt
```bash
# Ansible will prompt for vault password
ansible-playbook playbook.yml --ask-vault-pass

# Short form
ansible-playbook playbook.yml --vault-password-file
```

### Method 2: Password File
```bash
# Create password file (keep this secure!)
echo "your_vault_password" > ~/.vault_pass
chmod 600 ~/.vault_pass

# Use password file
ansible-playbook playbook.yml --vault-password-file ~/.vault_pass
```

### Method 3: Environment Variable
```bash
# Set environment variable
export ANSIBLE_VAULT_PASSWORD_FILE=~/.vault_pass

# Or inline
ANSIBLE_VAULT_PASSWORD_FILE=~/.vault_pass ansible-playbook playbook.yml
```

### Method 4: Configuration File
```ini
# In ansible.cfg
[defaults]
vault_password_file = ~/.vault_pass
```

## 🏗️ Project Structure with Vault

```
project/
├── ansible.cfg
├── inventory.yml
├── playbooks/
│   └── deploy.yml
├── group_vars/
│   ├── all/
│   │   ├── vars.yml          # Plain text variables
│   │   └── vault.yml         # Encrypted secrets
│   ├── production/
│   │   └── vault.yml         # Production secrets
│   └── staging/
│       └── vault.yml         # Staging secrets
└── host_vars/
    └── database-server/
        └── vault.yml         # Host-specific secrets
```

## 🛡️ Security Best Practices

### 1. **Password Management**
```bash
# Use strong, unique passwords for each vault
ansible-vault create --vault-id prod@prompt production-vault.yml
ansible-vault create --vault-id staging@prompt staging-vault.yml
```

### 2. **Multiple Vault IDs**
```bash
# Run with multiple vault passwords
ansible-playbook playbook.yml --vault-id prod@prompt --vault-id staging@prompt
```

### 3. **Vault File Naming**
```bash
# Use clear naming conventions
group_vars/all/vault.yml           # Global secrets
group_vars/production/vault.yml    # Environment-specific
host_vars/db-server/vault.yml     # Host-specific
```

### 4. **Git Integration**
```bash
# Add to .gitignore (NEVER commit these)
echo ".vault_pass" >> .gitignore
echo "*.key" >> .gitignore
echo "*.pem" >> .gitignore

# Vault files are safe to commit (they're encrypted)
git add group_vars/all/vault.yml   # This is OK - it's encrypted
```

## 🔄 Common Workflows

### Developer Workflow
```bash
# 1. Get vault password from team lead
# 2. Create password file
echo "team_vault_password" > ~/.project_vault_pass
chmod 600 ~/.project_vault_pass

# 3. View existing secrets
ansible-vault view group_vars/all/vault.yml --vault-password-file ~/.project_vault_pass

# 4. Add new secret
ansible-vault edit group_vars/all/vault.yml --vault-password-file ~/.project_vault_pass

# 5. Run playbook
ansible-playbook deploy.yml --vault-password-file ~/.project_vault_pass
```

### CI/CD Workflow
```yaml
# GitHub Actions example
- name: Run Ansible with vault
  env:
    ANSIBLE_VAULT_PASSWORD: ${{ secrets.VAULT_PASSWORD }}
  run: |
    echo "$ANSIBLE_VAULT_PASSWORD" > .vault_pass
    ansible-playbook deploy.yml --vault-password-file .vault_pass
    rm .vault_pass
```

## 🚨 Troubleshooting

### Common Issues
```bash
# Wrong password
ERROR! Decryption failed (no vault secrets were found that could decrypt)
# Solution: Check your vault password

# File not encrypted
ERROR! input is not vault encrypted data
# Solution: Use ansible-vault encrypt to encrypt the file first

# Multiple vault IDs confusion
ERROR! Multiple vault passwords were found but no vault ID was specified
# Solution: Use --vault-id to specify which vault to use
```

### Vault File Verification
```bash
# Check if file is encrypted
file group_vars/all/vault.yml
# Output: group_vars/all/vault.yml: ASCII text (if encrypted, will show as text)

# Verify vault format
head -1 group_vars/all/vault.yml
# Should show: $ANSIBLE_VAULT;1.1;AES256
```

## ✅ Benefits of Ansible Vault

1. **🆓 Free**: No additional cost
2. **🔒 Secure**: AES256 encryption
3. **📝 Version Control Safe**: Encrypted files can be committed to Git
4. **🔄 Team Friendly**: Share encrypted secrets safely
5. **🎯 Granular**: Different passwords for different environments
6. **🛠️ Integrated**: Works seamlessly with all Ansible features

Ansible Vault is the standard way to handle secrets in Ansible - it's robust, free, and widely adopted in the industry!
