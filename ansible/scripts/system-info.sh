#!/bin/bash

# Simple system information script
# Usage: ./system-info.sh [--env environment]

ENVIRONMENT="development"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --env)
            ENVIRONMENT="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

echo "=== System Information ==="
echo "Hostname: $(hostname)"
echo "Date: $(date)"
echo "Environment: $ENVIRONMENT"
echo "User: $(whoami)"

echo ""
echo "=== System Resources ==="
echo "CPU cores: $(nproc)"
echo "Memory: $(free -h | grep Mem | awk '{print $3 "/" $2}')"
echo "Disk usage: $(df -h / | tail -1 | awk '{print $5 " used"}')"

echo ""
echo "=== Software Versions ==="
[ -x "$(command -v git)" ] && echo "Git: $(git --version | cut -d' ' -f3)"
[ -x "$(command -v python3)" ] && echo "Python: $(python3 --version | cut -d' ' -f2)"
[ -x "$(command -v node)" ] && echo "Node.js: $(node --version)"

echo ""
echo "Script completed successfully!"
