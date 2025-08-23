# Ansible Playbooks

Three simple playbooks for common tasks.

## Playbooks

### patch-systems.yml
Updates all packages on target systems.

```bash
ansible-playbook ansible/playbooks/patch-systems.yml
```

### setup-local-dev.yml  
Installs development tools (git, python, nodejs).

```bash
ansible-playbook ansible/playbooks/setup-local-dev.yml
```

### execute-script.yml
Runs a local script on remote machines.

```bash
ansible-playbook ansible/playbooks/execute-script.yml -e "script_path=./ansible/scripts/system-info.sh"
```

## Options

All playbooks support:
- `target_group=groupname` - Target specific inventory group
- `--ask-become-pass` - Prompt for sudo password
- `-e "variable=value"` - Set custom variables

## Examples

```bash
# Patch only web servers
ansible-playbook ansible/playbooks/patch-systems.yml -e "target_group=webservers"

# Setup dev tools with sudo prompt
ansible-playbook ansible/playbooks/setup-local-dev.yml --ask-become-pass

# Run script with arguments
ansible-playbook ansible/playbooks/execute-script.yml -e "script_path=./ansible/scripts/deploy.sh" -e "script_args='--env prod'"
```
