#!/bin/bash
# Install WebLogic 12c
# set -e

echo "### 01_set_weblogic.sh - Installing WebLogic 12c..."

# Check root
if [ "$EUID" -ne 0 ]; then
    echo "[ERROR] Must run as root"
    exit 1
fi

# Environment setup
export ORACLE_BASE="/opt/oracle"
export ORACLE_HOME="$ORACLE_BASE/middleware"
export WLS_HOME="$ORACLE_HOME/wlserver"
export INSTALL_FILES_DIR="$ORACLE_BASE/install_files"

# Skip if already installed
if [ -d "$WLS_HOME" ]; then
    echo "[OK] WebLogic already installed"
    exit 0
fi


# Create user and directories
echo "- Creating weblogic user..."
groupadd -f weblogic
useradd -m -g weblogic weblogic 2>/dev/null || true
mkdir -p "$ORACLE_HOME" /opt/oracle/oraInventory
chown -R weblogic:weblogic "$ORACLE_HOME" /opt/oracle/oraInventory

# Setup Oracle inventory
echo "- Setting up Oracle inventory..."
cat > /etc/oraInst.loc << EOF
inventory_loc=/opt/oracle/oraInventory
inst_group=weblogic
EOF
chmod 644 /etc/oraInst.loc
chown weblogic:weblogic /opt/oracle/oraInventory

# Install prerequisites
echo "- Installing prerequisites..."
dnf update -y
dnf install -y wget unzip glibc-devel gcc libaio fontconfig

# Install Oracle JDK
echo "- Installing Oracle JDK..."
if [ ! -f "$INSTALL_FILES_DIR/jdk-8u461-linux-x64.rpm" ]; then
    echo "[ERROR] JDK RPM not found: $INSTALL_FILES_DIR/jdk-8u461-linux-x64.rpm"
    exit 1
fi

# Check if JDK is already installed
if rpm -qa | grep -q "jdk.*1\.8\.0_461"; then
    echo "[OK] Oracle JDK 8u461 already installed"
else
    echo "- Installing Oracle JDK 8u461..."
    # Capture both output and exit code
    rpm_output=$(rpm -ivh "$INSTALL_FILES_DIR/jdk-8u461-linux-x64.rpm" 2>&1)
    rpm_exit_code=$?
    
    if echo "$rpm_output" | grep -q "is already installed"; then
        echo "[OK] Oracle JDK was already installed"
    elif [ $rpm_exit_code -eq 0 ]; then
        echo "[OK] Oracle JDK installed successfully"
    else
        echo "[ERROR] Failed to install Oracle JDK RPM"
        echo "Error output: $rpm_output"
        exit 1
    fi
fi

export JAVA_HOME=/usr/java/latest
export PATH=$JAVA_HOME/bin:$PATH
echo "[OK] Java installed: $(java -version 2>&1 | head -1)"

# Install WebLogic
echo "- Installing WebLogic..."
WEBLOGIC_ZIP="$INSTALL_FILES_DIR/fmw_12.2.1.4.0_infrastructure_Disk1_1of1.zip"
if [ ! -f "$WEBLOGIC_ZIP" ]; then
    echo "[ERROR] WebLogic ZIP not found: $WEBLOGIC_ZIP"
    exit 1
fi

# Extract and install
TEMP_DIR="$INSTALL_FILES_DIR/tmp"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"
unzip -q "$WEBLOGIC_ZIP"

# Create response file for silent installation
cat > "$INSTALL_FILES_DIR/wls.rsp" << EOF
[ENGINE]
Response File Version=1.0.0.0.0
[GENERIC]
ORACLE_HOME=$ORACLE_HOME
INSTALL_TYPE=Fusion Middleware Infrastructure
DECLINE_SECURITY_UPDATES=true
SECURITY_UPDATES_VIA_MYORACLESUPPORT=false
EOF

# Install as weblogic user with proper inventory
echo "- Running Oracle installer..."
chown weblogic:weblogic "$INSTALL_FILES_DIR/wls.rsp"
su - weblogic -c "export JAVA_HOME=$JAVA_HOME && \
    export ORACLE_HOME=$ORACLE_HOME && \
    $JAVA_HOME/bin/java -jar $TEMP_DIR/fmw_12.2.1.4.0_infrastructure.jar \
    -silent \
    -responseFile $INSTALL_FILES_DIR/wls.rsp \
    -invPtrLoc /etc/oraInst.loc"

rm -rf "$TEMP_DIR"

if [ -d "$WLS_HOME" ]; then
    echo "[OK] WebLogic installation completed!"
else
    echo "[ERROR] WebLogic installation failed"
    exit 1
fi
