#!/bin/bash

# WebLogic 12c Full Distribution Setup for Development
# This script sets up WebLogic 12c in WSL or native Oracle Linux 8.10

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
export ORACLE_HOME="/opt/oracle"
export MW_HOME="$ORACLE_HOME/middleware"
export WLS_HOME="$MW_HOME/wlserver"
export DOMAIN_HOME="$MW_HOME/user_projects/domains"
export DOMAIN_NAME="test_domain"
export PORT=7001

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
oracle soft nofile 65536
oracle hard nofile 65536
oracle soft nproc 16384
oracle hard nproc 16384
oracle soft stack 10240
oracle hard stack 32768
EOF

# Create necessary directories
mkdir -p $ORACLE_HOME
mkdir -p $MW_HOME

# Configure package manager and repositories
echo "Configuring package manager and repositories..."
if command -v dnf &> /dev/null; then
    # Oracle Linux repositories
    if [ $IS_WSL -eq 0 ]; then
        echo "Enabling Oracle Linux repositories..."
        dnf config-manager --enable ol8_developer_EPEL
        dnf config-manager --enable ol8_codeready_builder
    else
        echo "Enabling WSL repositories..."
        dnf config-manager --add-repo https://yum.oracle.com/repo/OracleLinux/OL8/baseos/latest/x86_64
        dnf config-manager --add-repo https://yum.oracle.com/repo/OracleLinux/OL8/appstream/x86_64
    fi

    # Install prerequisites
    echo "Installing prerequisites..."
    dnf update -y
    
    # Try Oracle JDK first, fallback to OpenJDK
    if dnf list oracle-java-jdk-8 &>/dev/null; then
        dnf install -y wget unzip oracle-java-jdk-8 glibc-devel gcc libaio fontconfig
        export JAVA_HOME=/usr/java/latest
    else
        echo "Oracle JDK not found, installing OpenJDK..."
        dnf install -y wget unzip java-1.8.0-openjdk java-1.8.0-openjdk-devel glibc-devel gcc libaio fontconfig
        export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))
    fi
else
    echo "DNF not found. This script requires Oracle Linux 8 or compatible system."
    exit 1
fi

# Set Java environment
export JAVA_HOME=/usr/java/latest
export PATH=$JAVA_HOME/bin:$PATH

# Verify Java version
java -version

# Download WebLogic
echo "Downloading WebLogic 12c infrastructure installer..."
echo "Please provide your Oracle download token (from browser download URL):"
read -p "Token: " ORACLE_TOKEN

if [ -z "$ORACLE_TOKEN" ]; then
    echo "Token is required. Please get it from your Oracle account download page."
    exit 1
fi

# Oracle download URL with token
ORACLE_URL="https://download.oracle.com/otn/nt/middleware/12c/122140/fmw_12.2.1.4.0_infrastructure_Disk1_1of1.zip"
COOKIES="oraclelicense=accept-securebackup-cookie;ACCEPT_LICENSE_AGREEMENT=YES"

echo "Downloading WebLogic Infrastructure (this may take a while)..."
wget --no-check-certificate --no-cookies \
     --header "Cookie: ${COOKIES}" \
     --header "Authorization: Bearer ${ORACLE_TOKEN}" \
     -O $ORACLE_HOME/fmw_12.2.1.4.0_infrastructure_Disk1_1of1.zip \
     "${ORACLE_URL}"

if [ $? -ne 0 ]; then
    echo "Download failed. Please check your token and try again."
    exit 1
fi

echo "Download completed. Extracting..."

# Unzip the infrastructure installer
cd $ORACLE_HOME
unzip -q fmw_12.2.1.4.0_infrastructure_Disk1_1of1.zip

# Assuming the file is extracted as fmw_12.2.1.4.0_infrastructure.jar
# Create silent installation response file
cat > $ORACLE_HOME/wls.rsp << EOF
[ENGINE]
Response File Version=1.0.0.0.0
[GENERIC]
ORACLE_HOME=$ORACLE_HOME
INSTALL_TYPE=WebLogic Server
DECLINE_SECURITY_UPDATES=true
SECURITY_UPDATES_VIA_MYORACLESUPPORT=false
EOF

# Install WebLogic Infrastructure
echo "Installing WebLogic Infrastructure..."
$JAVA_HOME/bin/java -jar $ORACLE_HOME/fmw_12.2.1.4.0_infrastructure.jar -silent -responseFile $ORACLE_HOME/wls.rsp

# Create RCU schema for infrastructure
echo "Creating RCU schema..."
$ORACLE_HOME/oracle_common/bin/rcu -silent -createRepository \
    -databaseType ORACLE \
    -connectString localhost:1521:XE \
    -dbUser sys \
    -dbRole sysdba \
    -schemaPrefix DEV \
    -component STB \
    -component OPSS \
    -component IAU \
    -component IAU_APPEND \
    -component IAU_VIEWER

# Create test domain with infrastructure components
echo "Creating test domain..."
. $WLS_HOME/server/bin/setWLSEnv.sh

$JAVA_HOME/bin/java -Xmx1024m -Xms1024m \
    -cp $WLS_HOME/server/lib/weblogic.jar weblogic.Server \
    -configFile $DOMAIN_HOME/$DOMAIN_NAME/config/config.xml


