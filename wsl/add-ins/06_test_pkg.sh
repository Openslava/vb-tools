#!/bin/bash
# Test if package manager works

echo "🧪 Testing package manager..."

# Test apt (Ubuntu/Debian)
if command -v apt >/dev/null; then
    echo "📦 Testing apt..."
    timeout 30 apt update >/dev/null 2>&1 && { echo "✅ apt working"; exit 0; } || { echo "❌ apt failed"; exit 1; }

# Test yum (RHEL/CentOS/Oracle Linux)
elif command -v yum >/dev/null; then
    echo "📦 Testing yum..."
    timeout 30 yum check-update >/dev/null 2>&1
    [[ $? -eq 0 || $? -eq 100 ]] && { echo "✅ yum working"; exit 0; } || { echo "❌ yum failed"; exit 1; }

# Test dnf (Fedora/newer RHEL)
elif command -v dnf >/dev/null; then
    echo "📦 Testing dnf..."
    timeout 30 dnf check-update >/dev/null 2>&1
    [[ $? -eq 0 || $? -eq 100 ]] && { echo "✅ dnf working"; exit 0; } || { echo "❌ dnf failed"; exit 1; }

# No package manager found
else
    echo "❌ No package manager found"
    exit 1
fi
