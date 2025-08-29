#!/bin/bash
# System information script
set -e

ENVIRONMENT="${1:-development}"

echo "💻 System Information"
echo "Hostname: $(hostname) | Date: $(date)"
echo "Environment: $ENVIRONMENT | User: $(whoami)"
echo ""

echo "📊 Resources"
echo "CPU: $(nproc) cores | Memory: $(free -h | grep Mem | awk '{print $3 "/" $2}')"
echo "Disk: $(df -h / | tail -1 | awk '{print $5 " used"}')"
echo ""

echo "- Software"
command -v git >/dev/null && echo "Git: $(git --version | cut -d' ' -f3)"
command -v python3 >/dev/null && echo "Python: $(python3 --version | cut -d' ' -f2)"
command -v node >/dev/null && echo "Node.js: $(node --version)"

echo "[OK] System check completed!"
