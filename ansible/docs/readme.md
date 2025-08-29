# Ansible Documentation 📖

Guides and templates for Ansible automation.

## 📚 Guides

- **SECURE-DEPLOYMENT-GUIDE.md** - Public repos + secure credentials
- **ANSIBLE-VAULT-GUIDE.md** - Password encryption tutorial

## 📄 Templates

- **inventory-template.yml** - Project inventory structure
- **group_vars/all.yml.template** - Variables and configuration
- **deploy-project.sh.template** - Deployment script template
- **vault-example.yml** - Vault file structure example

## - Usage

```bash
# Copy templates to your project
cp ansible/docs/inventory-template.yml ../my-project/inventory.yml
cp ansible/docs/group_vars/all.yml.template ../my-project/group_vars/all.yml
cp ansible/docs/deploy-project.sh.template ../my-project/deploy.sh
```
