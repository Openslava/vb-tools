# Ansible Documentation

Comprehensive guides and configuration templates for Ansible automation.

## Guides

### SECURE-DEPLOYMENT-GUIDE.md
Best practices for using Ansible with public repositories while keeping credentials secure.

### ANSIBLE-VAULT-GUIDE.md  
Complete tutorial on using Ansible Vault for password encryption.

## Templates

### inventory-template.yml
Template for creating project-specific inventory files.

### group_vars/all.yml.template
Template for project variables and configuration.

### deploy-project.sh.template
Template for project deployment scripts.

### vault-example.yml
Example vault file structure (unencrypted sample).

## Usage

Copy templates to your project directories and customize:

```bash
# Copy inventory template
cp ansible/docs/inventory-template.yml ../my-project/inventory.yml

# Copy variables template  
cp ansible/docs/group_vars/all.yml.template ../my-project/group_vars/all.yml

# Copy deployment script
cp ansible/docs/deploy-project.sh.template ../my-project/deploy.sh
```

Refer to the guides for detailed setup instructions and security best practices.
