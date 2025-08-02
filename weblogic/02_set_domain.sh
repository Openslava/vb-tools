#!/bin/bash

# WebLogic Domain Creation Script - Simplified Version
# This script creates a WebLogic domain with basic configuration

# Set environment variables
export ORACLE_BASE="/opt/oracle"
export ORACLE_HOME="$ORACLE_BASE/middleware"
export WLS_HOME="$ORACLE_HOME/wlserver"
export DOMAIN_HOME="$ORACLE_HOME/user_projects/domains"
export DOMAIN_NAME=${1:-"test_domain"}
export PORT=${PORT:-7001}
export ADMIN_USER=${ADMIN_USER:-"weblogic"}

# Find Java installation
if [ -d "/usr/java/latest" ]; then
    export JAVA_HOME=/usr/java/latest
elif [ -d "/usr/lib/jvm/java-1.8.0" ]; then
    export JAVA_HOME=/usr/lib/jvm/java-1.8.0
else
    echo "Error: Java installation not found"
    exit 1
fi

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root or with sudo"
    exit 1
fi

# Check if WebLogic is installed
if [ ! -d "$WLS_HOME" ]; then
    echo "Error: WebLogic installation not found at $WLS_HOME"
    exit 1
fi

# Get admin password
if [ -z "$ADMIN_PASSWORD" ]; then
    echo -n "Enter WebLogic admin password: "
    read -s ADMIN_PASSWORD
    echo
fi

# Remove existing domain if it exists
[ -d "$DOMAIN_HOME/$DOMAIN_NAME" ] && rm -rf "$DOMAIN_HOME/$DOMAIN_NAME"

echo "Creating WebLogic domain: $DOMAIN_NAME"

# Create domain directory
mkdir -p "$DOMAIN_HOME"

# Create and run WLST script
cat > /tmp/create_domain.py << EOF
readTemplate('$WLS_HOME/common/templates/wls/wls.jar')
setOption('DomainName', '$DOMAIN_NAME')
setOption('ServerStartMode', 'prod')
setOption('JavaHome', '$JAVA_HOME')
cd('/Security/base_domain/User/weblogic')
cmo.setPassword('$ADMIN_PASSWORD')
cd('/Servers/AdminServer')
set('ListenPort', $PORT)
setOption('NodeManagerType', 'PerDomainNodeManager')
setOption('NodeManagerUsername', '$ADMIN_USER')
setOption('NodeManagerPassword', '$ADMIN_PASSWORD')
writeDomain('$DOMAIN_HOME/$DOMAIN_NAME')
closeTemplate()
exit()
EOF

# Create domain
su - weblogic -c "export JAVA_HOME=$JAVA_HOME && $WLS_HOME/../oracle_common/common/bin/wlst.sh /tmp/create_domain.py"
rm -f /tmp/create_domain.py

# Set permissions
chown -R weblogic:weblogic "$DOMAIN_HOME/$DOMAIN_NAME"
chmod -R 750 "$DOMAIN_HOME/$DOMAIN_NAME"

echo "Domain $DOMAIN_NAME created successfully!"
echo "Admin console: http://localhost:$PORT/console"
echo "To start: sudo su - weblogic && $DOMAIN_HOME/$DOMAIN_NAME/bin/startWebLogic.sh"
