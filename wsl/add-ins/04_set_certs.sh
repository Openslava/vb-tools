#!/bin/bash
# Configure WSL to use Windows CA certificates
set -e

CERT_FILE="${1:-/tmp/windows-ca-certificates.crt}"
CERT_DIR="/etc/pki/ca-trust/source/anchors"

echo "🔐 Installing Windows CA certificates..."

# Check root privileges
if [[ $EUID -ne 0 ]]; then
    echo "❌ Must run as root: sudo $0"
    exit 1
fi

# Install ca-certificates package
if ! rpm -q ca-certificates >/dev/null 2>&1; then
    echo "📦 Installing ca-certificates..."
    if command -v dnf >/dev/null; then dnf install -y ca-certificates; else yum install -y ca-certificates; fi
fi

# Test HTTPS first
echo "🌐 Testing HTTPS connectivity..."
test_sites=("https://www.microsoft.com" "https://www.google.com")
working=0
for site in "${test_sites[@]}"; do
    if timeout 5 curl -s "$site" >/dev/null 2>&1; then
        echo "✅ $site - OK"
        working=$((working + 1))
    fi
done

# Skip if HTTPS already works
if [[ $working -eq ${#test_sites[@]} ]]; then
    echo "✅ HTTPS working - no certificates needed!"
    exit 0
fi

# Validate certificate file
if [[ ! -f "$CERT_FILE" ]]; then
    echo "❌ Certificate file not found: $CERT_FILE"
    exit 1
fi

cert_count=$(grep -c "BEGIN CERTIFICATE" "$CERT_FILE" 2>/dev/null || echo "0")
if [[ $cert_count -eq 0 ]]; then
    echo "❌ No certificates found in file"
    exit 1
fi

echo "📤 Installing $cert_count certificates..."

# Install certificates
mkdir -p "$CERT_DIR"
cp "$CERT_FILE" "$CERT_DIR/windows-ca-certificates.crt"
chmod 644 "$CERT_DIR/windows-ca-certificates.crt"

# Update trust store
if command -v update-ca-trust >/dev/null; then
    update-ca-trust
elif command -v update-ca-certificates >/dev/null; then
    update-ca-certificates
else
    echo "❌ No CA update command found"
    exit 1
fi

# Test again
echo "🧪 Re-testing HTTPS..."
working=0
for site in "${test_sites[@]}"; do
    if timeout 5 curl -s "$site" >/dev/null 2>&1; then
        echo "✅ $site - OK"
        working=$((working + 1))
    fi
done

echo "🎉 Completed! HTTPS tests: $working/${#test_sites[@]} working"
