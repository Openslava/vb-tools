#!/bin/bash

# WebLogic 12c Full Distribution Setup for Development
# This script sets up WebLogic 12c in WSL or native Oracle Linux 8.10
# prereqiosite to download and place the WebLogic installer in /opt/oracle/install_files
# cp /mnt/g/WSB/install/weblogic/jdk-8u461-linux-x64.rpm  /opt/oracle/install_files/
# cp /mnt/g/WSB/install/weblogic/fmw_12.2.1.4.0_infrastructure_Disk1_1of1.zip  /opt/oracle/install_files/

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root or with sudo"
    exit 1
fi

# Detect environment
IS_WSL=0
if grep -qi microsoft /proc/version; then
    IS_WSL=1
    echo "WSL environment detected"
else
    echo "Native Oracle Linux environment detected"
fi

# Environment variables
export ORACLE_BASE="/opt/oracle"
export ORACLE_HOME="$ORACLE_BASE/middleware"
export MW_HOME="$ORACLE_HOME"
export WLS_HOME="$MW_HOME/wlserver"
export INSTALL_FILES_DIR="$ORACLE_BASE/install_files"

# System settings for Oracle Linux
echo "Configuring system settings..."

# SELinux configuration (skip in WSL)
if [ $IS_WSL -eq 0 ] && [ -f /etc/selinux/config ]; then
    echo "Configuring SELinux..."
    sed -i 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config
    setenforce 0
fi

# Adjust kernel parameters (skip in WSL)
if [ $IS_WSL -eq 0 ]; then
    echo "Configuring kernel parameters..."
    cat >> /etc/sysctl.conf << EOF
fs.file-max = 65536
net.ipv4.ip_local_port_range = 9000 65500
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
EOF
    sysctl -p
else
    echo "Skipping kernel parameter configuration in WSL"
fi

# Set user limits
cat >> /etc/security/limits.conf << EOF
weblogic soft nofile 65536
weblogic hard nofile 65536
weblogic soft nproc 16384
weblogic hard nproc 16384
weblogic soft stack 10240
weblogic hard stack 32768
EOF

# Create WebLogic user and group
echo "Creating WebLogic user and group..."
groupadd -f weblogic
useradd -m -g weblogic -G wheel weblogic 2>/dev/null || echo "User weblogic already exists"

# Create and prepare Oracle directories
echo "Preparing Oracle directories..."

# Remove existing Oracle directories if they exist
echo "Cleaning up existing Oracle directories..."
rm -rf "$ORACLE_HOME"
rm -rf "$MW_HOME"
rm -rf /opt/oracle/oraInventory

# Create fresh directories
echo "Creating fresh Oracle directories..."
# Create installation files directory
mkdir -p "$INSTALL_FILES_DIR"
mkdir -p "$DOMAIN_HOME"
mkdir -p "$ORACLE_HOME"
mkdir -p "$MW_HOME"
mkdir -p /opt/oracle/oraInventory

# Create oraInst.loc file
cat > /etc/oraInst.loc << EOF
inventory_loc=/opt/oracle/oraInventory
inst_group=weblogic
EOF

# Set correct ownership and permissions
echo "Setting correct ownership and permissions..."
chown -R weblogic:weblogic $ORACLE_HOME
chown -R weblogic:weblogic $MW_HOME

chown -R weblogic:weblogic /opt/oracle/oraInventory
chmod 775 /opt/oracle/oraInventory
chmod 775 $ORACLE_HOME
chmod 775 $DOMAIN_HOME

# Configure package manager and repositories
echo "Configuring package manager and repositories..."
if command -v dnf &> /dev/null; then
    # Install dnf config manager if not present
    dnf install -y dnf-utils

    # Oracle Linux repositories
    if [ $IS_WSL -eq 0 ]; then
        echo "Enabling Oracle Linux repositories..."
        dnf install -y oracle-epel-release-el8
        dnf config-manager --enable ol8_baseos_latest
        dnf config-manager --enable ol8_appstream
        dnf config-manager --enable ol8_addons
        dnf config-manager --enable ol8_oracle_instantclient
    else
        echo "Enabling WSL repositories..."
        dnf install -y oracle-epel-release-el8
        dnf config-manager --add-repo https://yum.oracle.com/repo/OracleLinux/OL8/baseos/latest/x86_64
        dnf config-manager --add-repo https://yum.oracle.com/repo/OracleLinux/OL8/appstream/x86_64
        dnf config-manager --add-repo https://yum.oracle.com/repo/OracleLinux/OL8/addons/x86_64
    fi

    # Install prerequisites
    echo "Installing prerequisites..."
    dnf update -y
    
    # Install prerequisites
    dnf install -y wget unzip glibc-devel gcc libaio fontconfig

    # Check for manually downloaded Oracle JDK
    if [ ! -f "$INSTALL_FILES_DIR/jdk-8u461-linux-x64.rpm" ]; then
        echo "Oracle JDK RPM not found. Please download jdk-8u461-linux-x64.rpm from Oracle and place it in $INSTALL_FILES_DIR/"
        echo "Download URL: https://www.oracle.com/java/technologies/javase/javase8-archive-downloads.html"
        echo "You can copy it using: cp /mnt/g/WSB/install/weblogic/jdk-8u461-linux-x64.rpm $INSTALL_FILES_DIR/"
        exit 1
    fi

    # Install Oracle JDK RPM
    rpm -ivh "$INSTALL_FILES_DIR/jdk-8u461-linux-x64.rpm"

    # Verify Oracle JDK installation
    if [ ! -d "/usr/java/latest" ]; then
        echo "Oracle JDK installation failed. Please check repository access."
        exit 1
    fi
    
    export JAVA_HOME=/usr/java/latest
else
    echo "DNF not found. This script requires Oracle Linux 8 or compatible system."
    exit 1
fi

# Set Java environment
if [ -d "/usr/java/latest" ]; then
    export JAVA_HOME=/usr/java/latest
elif [ -d "/usr/lib/jvm/java-1.8.0" ]; then
    export JAVA_HOME=/usr/lib/jvm/java-1.8.0
else
    # Try to find Java installation
    possible_java_paths=(
        $(update-alternatives --list java 2>/dev/null | grep -i "java-8" | sed 's/\/bin\/java$//')
        "/usr/lib/jvm/java-8-openjdk-amd64"
        "/usr/lib/jvm/java-8-openjdk"
    )
    
    for java_path in "${possible_java_paths[@]}"; do
        if [ -d "$java_path" ]; then
            export JAVA_HOME="$java_path"
            break
        fi
    done
fi

if [ -z "$JAVA_HOME" ]; then
    echo "Error: Could not find Java installation. Please install Java 8 first."
    exit 1
fi

export PATH=$JAVA_HOME/bin:$PATH

# Verify Java version
echo "Using Java at: $JAVA_HOME"
java -version

# Check for WebLogic installer
WEBLOGIC_INSTALLER="$INSTALL_FILES_DIR/fmw_12.2.1.4.0_infrastructure_Disk1_1of1.zip"

if [ ! -f "$WEBLOGIC_INSTALLER" ]; then
    echo "WebLogic installer not found at: $WEBLOGIC_INSTALLER"
    echo "Please download fmw_12.2.1.4.0_infrastructure_Disk1_1of1.zip from: https://www.oracle.com/qa/middleware/technologies/weblogic-server-downloads.html#license-lightbox"
    echo "You can copy it using: cp /mnt/g/WSB/install/weblogic/fmw_12.2.1.4.0_infrastructure_Disk1_1of1.zip $INSTALL_FILES_DIR/"
    exit 1
fi

echo "Found WebLogic installer, proceeding with installation..."
echo "Extracting..."

# Create temporary directory for extraction
TEMP_EXTRACT_DIR="$INSTALL_FILES_DIR/tmp_extract"
mkdir -p "$TEMP_EXTRACT_DIR"
cd "$TEMP_EXTRACT_DIR"

# Unzip the infrastructure installer
unzip -q "$WEBLOGIC_INSTALLER"

# Verify the jar exists
if [ ! -f "$TEMP_EXTRACT_DIR/fmw_12.2.1.4.0_infrastructure.jar" ]; then
    echo "Error: Infrastructure jar not found in extracted files"
    exit 1
fi

# Assuming the file is extracted as fmw_12.2.1.4.0_infrastructure.jar
# Create silent installation response file
cat > $INSTALL_FILES_DIR/wls.rsp << EOF
[ENGINE]
Response File Version=1.0.0.0.0
[GENERIC]
ORACLE_HOME=$ORACLE_HOME
INSTALL_TYPE=Fusion Middleware Infrastructure
DECLINE_SECURITY_UPDATES=true
SECURITY_UPDATES_VIA_MYORACLESUPPORT=false
INVENTORY_LOCATION=/opt/oracle/oraInventory
EOF

# Ensure ORACLE_HOME is completely empty
rm -rf "$ORACLE_HOME"/*

# Install WebLogic Infrastructure
echo "Installing WebLogic Infrastructure..."
# Run installation as weblogic user
su - weblogic -c "export JAVA_HOME=$JAVA_HOME && \
    export PATH=$JAVA_HOME/bin:$PATH && \
    $JAVA_HOME/bin/java -jar $TEMP_EXTRACT_DIR/fmw_12.2.1.4.0_infrastructure.jar -silent -responseFile $INSTALL_FILES_DIR/wls.rsp"

INSTALL_STATUS=$?

# Clean up the temporary directory
cd "$INSTALL_FILES_DIR"
rm -rf "$TEMP_EXTRACT_DIR"

if [ $INSTALL_STATUS -ne 0 ]; then
    echo "WebLogic installation failed"
    exit 1
fi

echo "WebLogic installation completed successfully"

# Oracle Database and RCU Configuration
# Default values for database connection
DB_HOST=${DB_HOST:-"localhost"}
DB_PORT=${DB_PORT:-"1521"}
DB_SERVICE=${DB_SERVICE:-"XE"}
DB_SYS_PASSWORD=${DB_SYS_PASSWORD:-""}
SCHEMA_PREFIX=${SCHEMA_PREFIX:-"DEV"}

# Check for Oracle Database and create RCU schemas if needed
if [ -f "$ORACLE_HOME/oracle_common/bin/rcu" ]; then
    if nc -z $DB_HOST $DB_PORT 2>/dev/null; then
        echo "Oracle Database detected at $DB_HOST:$DB_PORT"
        
        # Ask for SYS password if not provided and running interactively
        if [ -z "$DB_SYS_PASSWORD" ] && [ -t 0 ]; then
            read -s -p "Enter SYS password for Oracle Database: " DB_SYS_PASSWORD
            echo
        fi
        
        if [ -n "$DB_SYS_PASSWORD" ]; then
            echo "Creating RCU schemas with prefix: $SCHEMA_PREFIX"
            echo "Using database connection: $DB_HOST:$DB_PORT/$DB_SERVICE"
            
            # Create RCU schemas
            su - weblogic -c "export JAVA_HOME=$JAVA_HOME && \
                $ORACLE_HOME/oracle_common/bin/rcu -silent -createRepository \
                -databaseType ORACLE \
                -connectString $DB_HOST:$DB_PORT/$DB_SERVICE \
                -dbUser sys \
                -dbRole sysdba \
                -dbPassword $DB_SYS_PASSWORD \
                -schemaPrefix $SCHEMA_PREFIX \
                -component STB \
                -component OPSS \
                -component IAU \
                -component MDS \
                -component WLS"
            
            RCU_STATUS=$?
            if [ $RCU_STATUS -eq 0 ]; then
                echo "RCU schemas created successfully"
                # Create a file to store schema information
                echo "SCHEMA_PREFIX=$SCHEMA_PREFIX" > "$INSTALL_FILES_DIR/rcu_info.properties"
                echo "DB_CONNECT_STRING=$DB_HOST:$DB_PORT/$DB_SERVICE" >> "$INSTALL_FILES_DIR/rcu_info.properties"
            else
                echo "RCU schema creation failed (Status: $RCU_STATUS)"
                echo "Please check:"
                echo "1. Database connectivity to $DB_HOST:$DB_PORT/$DB_SERVICE"
                echo "2. SYS user credentials"
                echo "3. Available tablespace"
                echo "Continuing with installation..."
            fi
        else
            echo "No database password provided. Skipping RCU schema creation."
        fi
    else
        echo "Oracle Database not found at $DB_HOST:$DB_PORT"
        echo "To create RCU schemas later, you can:"
        echo "1. Set DB_HOST, DB_PORT, DB_SERVICE environment variables"
        echo "2. Set DB_SYS_PASSWORD for non-interactive execution"
        echo "3. Run: $ORACLE_HOME/oracle_common/bin/rcu"
    fi
else
    echo "RCU tool not found at $ORACLE_HOME/oracle_common/bin/rcu"
    echo "Please ensure WebLogic Infrastructure installation completed successfully"
fi

# Installation completed
if [ -d "$WLS_HOME" ]; then
    echo "WebLogic installation completed successfully"
    echo "You can now create a domain using 02_set_domain.sh"
    echo "Usage: sudo ./02_set_domain.sh [domain_name]"
    echo "Example: sudo ./02_set_domain.sh my_domain"
else
    echo "WebLogic installation directory not found at $WLS_HOME"
    echo "Installation might have failed or path is incorrect"
fi
