#!/bin/bash

# Setup ISO as local repository in Oracle Linux WSL
# Usage: ./05_setup_iso_repo.sh [iso_path] [mount_point] [options]

set -e

# Default values
MOUNT_POINT="/mnt/iso-repo"
PERMANENT=false
REPLACE_REPOS=false
BACKUP_DIR="/etc/yum.repos.d/backup"

# Function to show usage
show_usage() {
    echo "🔧 Setup ISO as Local Repository"
    echo ""
    echo "Usage: $0 [OPTIONS] ISO_PATH"
    echo ""
    echo "Options:"
    echo "  -m, --mount-point PATH    Mount point for ISO (default: $MOUNT_POINT)"
    echo "  -p, --permanent          Add to /etc/fstab for permanent mounting"
    echo "  -r, --replace-repos      Replace existing repositories"
    echo "  -h, --help               Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 /mnt/c/ISOs/OracleLinux-R8-U10-x86_64-dvd.iso"
    echo "  $0 -p -m /media/oracle-iso /mnt/c/ISOs/oracle.iso"
    echo "  $0 --replace-repos /mnt/c/Downloads/OracleLinux.iso"
    echo ""
    echo "💡 Download Oracle Linux ISO from:"
    echo "   https://yum.oracle.com/oracle-linux-isos.html"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -m|--mount-point)
            MOUNT_POINT="$2"
            shift 2
            ;;
        -p|--permanent)
            PERMANENT=true
            shift
            ;;
        -r|--replace-repos)
            REPLACE_REPOS=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        -*)
            echo "[ERROR] Unknown option: $1"
            show_usage
            exit 1
            ;;
        *)
            ISO_PATH="$1"
            shift
            ;;
    esac
done

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "[ERROR] This script must be run as root"
    echo "Run: sudo $0 $*"
    exit 1
fi

# Validate ISO path
if [ -z "$ISO_PATH" ]; then
    echo "[ERROR] ISO path is required"
    show_usage
    exit 1
fi

if [ ! -f "$ISO_PATH" ]; then
    echo "[ERROR] ISO file not found: $ISO_PATH"
    echo ""
    echo "💡 Common locations for Windows-mounted ISOs:"
    echo "   /mnt/c/ISOs/"
    echo "   /mnt/c/Downloads/"
    echo "   /mnt/d/Software/"
    exit 1
fi

echo "🔧 Setting up ISO as local repository"
echo "ISO Path: $ISO_PATH"
echo "Mount Point: $MOUNT_POINT"
echo "Permanent: $PERMANENT"
echo "Replace existing repos: $REPLACE_REPOS"
echo ""

# Create mount point
echo "📁 Creating mount point..."
mkdir -p "$MOUNT_POINT"

# Check if already mounted
if mountpoint -q "$MOUNT_POINT"; then
    echo "⚠️ Mount point already in use, unmounting..."
    umount "$MOUNT_POINT"
fi

# Mount the ISO
echo "💿 Mounting ISO..."
mount -o loop,ro "$ISO_PATH" "$MOUNT_POINT"

# Verify mount
if ! mountpoint -q "$MOUNT_POINT"; then
    echo "[ERROR] Failed to mount ISO"
    exit 1
fi

echo "✅ ISO mounted successfully at $MOUNT_POINT"

# Check ISO contents
echo "🔍 Checking ISO contents..."
ls -la "$MOUNT_POINT"

# Detect repository structure
REPO_TYPE="unknown"
if [ -d "$MOUNT_POINT/BaseOS" ] || [ -d "$MOUNT_POINT/AppStream" ]; then
    echo "✅ Found Oracle Linux 8 repository structure"
    REPO_TYPE="ol8"
elif [ -d "$MOUNT_POINT/Packages" ]; then
    echo "✅ Found Oracle Linux 7 repository structure"
    REPO_TYPE="ol7"
else
    echo "⚠️ Unknown repository structure"
    echo "Available directories:"
    find "$MOUNT_POINT" -maxdepth 2 -type d | head -10
fi

# Handle existing repositories if replace option is used
if [ "$REPLACE_REPOS" = true ]; then
    echo "📋 Backing up existing repositories..."
    mkdir -p "$BACKUP_DIR"
    cp /etc/yum.repos.d/*.repo "$BACKUP_DIR/" 2>/dev/null || true
    
    echo "🔒 Disabling existing repositories..."
    sed -i 's/enabled=1/enabled=0/g' /etc/yum.repos.d/*.repo
fi

# Create repository configuration
echo "📝 Creating local repository configuration..."

if [ "$REPLACE_REPOS" = true ]; then
    # Replace mode - use standard repository names
    cat > /etc/yum.repos.d/local-iso.repo << EOF
# Local ISO Repository Configuration (Replace Mode)
# Created: $(date)
# ISO: $ISO_PATH
# Mount: $MOUNT_POINT

[local-baseos]
name=Local ISO - BaseOS
baseurl=file://$MOUNT_POINT/BaseOS
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-oracle

[local-appstream]
name=Local ISO - AppStream
baseurl=file://$MOUNT_POINT/AppStream
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-oracle

EOF
else
    # Additive mode - use unique repository names with higher priority
    cat > /etc/yum.repos.d/local-iso.repo << EOF
# Local ISO Repository Configuration (Additive Mode)
# Created: $(date)
# ISO: $ISO_PATH
# Mount: $MOUNT_POINT

[local-iso-baseos]
name=Local ISO - BaseOS
baseurl=file://$MOUNT_POINT/BaseOS
enabled=1
gpgcheck=0
priority=1

[local-iso-appstream]
name=Local ISO - AppStream
baseurl=file://$MOUNT_POINT/AppStream
enabled=1
gpgcheck=0
priority=1

EOF
fi

# Add to fstab for permanent mounting if requested
if [ "$PERMANENT" = true ]; then
    echo "🔧 Adding to /etc/fstab for permanent mounting..."
    # Remove any existing entry for this mount point
    grep -v "$MOUNT_POINT" /etc/fstab > /tmp/fstab.new || true
    echo "$ISO_PATH $MOUNT_POINT iso9660 loop,ro,auto 0 0" >> /tmp/fstab.new
    mv /tmp/fstab.new /etc/fstab
    echo "✅ Added to /etc/fstab"
fi

# Clean yum cache
echo "🧹 Cleaning package cache..."
yum clean all

# Test repository
echo "- Testing repository configuration..."
yum repolist

# Show available packages
echo "- Sample packages available from ISO:"
yum list available | head -20

echo ""
echo "🎉 ISO repository setup completed successfully!"
echo ""
echo "📋 Repository Information:"
echo "  Mount Point: $MOUNT_POINT"
echo "  Configuration: /etc/yum.repos.d/local-iso.repo"
echo "  Permanent: $([ "$PERMANENT" = true ] && echo "Yes (added to /etc/fstab)" || echo "No (mount will not survive reboot)")"
echo "  Mode: $([ "$REPLACE_REPOS" = true ] && echo "Replaced existing repositories" || echo "Added alongside existing repositories")"
echo ""
echo "💡 Usage:"
echo "  yum install package-name    # Install from local ISO"
echo "  yum repolist               # List all repositories"
echo "  yum list available         # List available packages"
echo ""
if [ "$REPLACE_REPOS" = true ]; then
    echo "- To restore original repositories:"
    echo "  cp $BACKUP_DIR/*.repo /etc/yum.repos.d/"
    echo "  rm /etc/yum.repos.d/local-iso.repo"
    echo ""
fi
if [ "$PERMANENT" = false ]; then
    echo "⚠️  To unmount: umount $MOUNT_POINT"
fi
