#!/bin/bash

# WebLogic 12c Installation Script - Simplified Version
# This script installs WebLogic 12c with basic configuration
# Prerequisites: Place these files in /opt/oracle/install_files/
# - jdk-8u461-linux-x64.rpm
# - fmw_12.2.1.4.0_infrastructure_Disk1_1of1.zip

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root or with sudo"
    exit 1
fi

# Environment variables
export ORACLE_BASE="/opt/oracle"
export ORACLE_HOME="$ORACLE_BASE/middleware"
export WLS_HOME="$ORACLE_HOME/wlserver"
export INSTALL_FILES_DIR="$ORACLE_BASE/install_files"

echo "Setting up WebLogic 12c..."

# Create WebLogic user and group
echo "Creating WebLogic user..."
groupadd -f weblogic
useradd -m -g weblogic weblogic 2>/dev/null || echo "User weblogic already exists"

# Create directories
echo "Creating directories..."
rm -rf "$ORACLE_HOME"
mkdir -p "$INSTALL_FILES_DIR"
mkdir -p "$ORACLE_HOME"
mkdir -p /opt/oracle/oraInventory

# Set permissions
chown -R weblogic:weblogic "$ORACLE_HOME"
chown -R weblogic:weblogic /opt/oracle/oraInventory

# Create oraInst.loc file
cat > /etc/oraInst.loc << EOF
inventory_loc=/opt/oracle/oraInventory
inst_group=weblogic
EOF

# Install prerequisites
echo "Installing prerequisites..."
dnf update -y
dnf install -y wget unzip glibc-devel gcc libaio fontconfig

# Install Oracle JDK
echo "Installing Oracle JDK..."
if [ ! -f "$INSTALL_FILES_DIR/jdk-8u461-linux-x64.rpm" ]; then
    echo "Error: Oracle JDK RPM not found at $INSTALL_FILES_DIR/jdk-8u461-linux-x64.rpm"
    echo "Please download and place the file there first"
    exit 1
fi

rpm -ivh "$INSTALL_FILES_DIR/jdk-8u461-linux-x64.rpm"

# Set Java environment
if [ -d "/usr/java/latest" ]; then
    export JAVA_HOME=/usr/java/latest
else
    echo "Error: Oracle JDK installation failed"
    exit 1
fi

export PATH=$JAVA_HOME/bin:$PATH
echo "Using Java at: $JAVA_HOME"
java -version

# Install WebLogic
echo "Installing WebLogic..."
WEBLOGIC_INSTALLER="$INSTALL_FILES_DIR/fmw_12.2.1.4.0_infrastructure_Disk1_1of1.zip"

if [ ! -f "$WEBLOGIC_INSTALLER" ]; then
    echo "Error: WebLogic installer not found at $WEBLOGIC_INSTALLER"
    echo "Please download and place the file there first"
    exit 1
fi

# Extract installer
TEMP_DIR="$INSTALL_FILES_DIR/tmp"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"
unzip -q "$WEBLOGIC_INSTALLER"

# Create response file
cat > "$INSTALL_FILES_DIR/wls.rsp" << EOF
[ENGINE]
Response File Version=1.0.0.0.0
[GENERIC]
ORACLE_HOME=$ORACLE_HOME
INSTALL_TYPE=Fusion Middleware Infrastructure
DECLINE_SECURITY_UPDATES=true
SECURITY_UPDATES_VIA_MYORACLESUPPORT=false
INVENTORY_LOCATION=/opt/oracle/oraInventory
EOF

# Install WebLogic
su - weblogic -c "export JAVA_HOME=$JAVA_HOME && \
    $JAVA_HOME/bin/java -jar $TEMP_DIR/fmw_12.2.1.4.0_infrastructure.jar -silent -responseFile $INSTALL_FILES_DIR/wls.rsp"

# Clean up
rm -rf "$TEMP_DIR"

# Verify installation
if [ -d "$WLS_HOME" ]; then
    echo "WebLogic installation completed successfully!"
    echo "Next step: Run ./02_set_domain.sh to create a domain"
else
    echo "Error: WebLogic installation failed"
    exit 1
fi
