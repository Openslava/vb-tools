# Ansible Example Scripts

This directory contains example scripts used by Ansible playbooks.

## Scripts

- `system-info.sh` - Simple system information gathering script
  - Used by: `../playbooks/execute-script.yml`
  - Usage: `./system-info.sh [--env environment]`
  - Purpose: Demonstrates remote script execution via Ansible
