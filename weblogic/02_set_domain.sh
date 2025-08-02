#!/bin/bash

# WebLogic Domain Creation Script
# This script creates a WebLogic domain with configurable parameters

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root or with sudo"
    exit 1
fi

# Default environment variables
export ORACLE_BASE="/opt/oracle"
export ORACLE_HOME="$ORACLE_BASE/middleware"
export MW_HOME="$ORACLE_HOME"
export WLS_HOME="$MW_HOME/wlserver"
export DOMAIN_HOME="$MW_HOME/user_projects/domains"
export INSTALL_FILES_DIR="$ORACLE_BASE/install_files"

# Default values that can be overridden
export DOMAIN_NAME=${1:-"test_domain"}
export PORT=${PORT:-7001}
export ADMIN_USER=${ADMIN_USER:-"weblogic"}
export ADMIN_PASSWORD=${ADMIN_PASSWORD:-"welcome1"}

# Check if WebLogic is installed
if [ ! -d "$WLS_HOME" ]; then
    echo "Error: WebLogic installation not found at $WLS_HOME"
    echo "Please run 01_set_weblogic.sh first to install WebLogic"
    exit 1
fi

# Set Java environment
if [ -d "/usr/java/latest" ]; then
    export JAVA_HOME=/usr/java/latest
elif [ -d "/usr/lib/jvm/java-1.8.0" ]; then
    export JAVA_HOME=/usr/lib/jvm/java-1.8.0
else
    echo "Error: Java installation not found"
    exit 1
fi

export PATH=$JAVA_HOME/bin:$PATH

echo "Creating WebLogic domain: $DOMAIN_NAME"
echo "Domain will be created at: $DOMAIN_HOME/$DOMAIN_NAME"
echo "Admin server will run on port: $PORT"

# Check if domain already exists
if [ -d "$DOMAIN_HOME/$DOMAIN_NAME" ]; then
    read -p "Domain $DOMAIN_NAME already exists. Do you want to delete it? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Removing existing domain..."
        rm -rf "$DOMAIN_HOME/$DOMAIN_NAME"
    else
        echo "Aborting domain creation"
        exit 1
    fi
fi

# Prepare domain directory
mkdir -p "$DOMAIN_HOME"
chown -R weblogic:weblogic "$DOMAIN_HOME"
chmod -R 775 "$DOMAIN_HOME"

# Create domain configuration file
CONFIG_FILE="$INSTALL_FILES_DIR/domain.properties"
cat > "$CONFIG_FILE" << EOF
[ENGINE]
Response File Version=1.0.0.0.0

[GENERIC]
DOMAIN_TYPE=WLS
DOMAIN_NAME=$DOMAIN_NAME
DOMAIN_HOME=$DOMAIN_HOME/$DOMAIN_NAME
ADMIN_PORT=$PORT
ADMIN_SERVER_NAME=AdminServer
ADMIN_USER=$ADMIN_USER
ADMIN_PASSWORD=$ADMIN_PASSWORD
PRODUCTION_MODE=true

[DOMAINS]
CREATE_DOMAIN=true
CONFIGURATION_TEMPLATE=$WLS_HOME/common/templates/wls/wls.jar
DOMAIN_TEMPLATE=$WLS_HOME/common/templates/wls/wls.jar
OVERWRITE_DOMAIN=true
SERVER_START_MODE=prod

[SECURITY]
CONFIGURE_NODE_MANAGER=true
NODE_MANAGER_USERNAME=$ADMIN_USER
NODE_MANAGER_PASSWORD=$ADMIN_PASSWORD
NODE_MANAGER_TYPE=PerDomainNodeManager
EOF

# If RCU schemas exist, add database configuration
RCU_INFO_FILE="$INSTALL_FILES_DIR/rcu_info.properties"
if [ -f "$RCU_INFO_FILE" ]; then
    source "$RCU_INFO_FILE"
    echo "Found RCU schema information:"
    echo "Schema Prefix: $SCHEMA_PREFIX"
    echo "Database: $DB_CONNECT_STRING"
    
    cat >> "$CONFIG_FILE" << EOF

[DATABASE]
Database Type=Oracle
Connect String=$DB_CONNECT_STRING
Schema Prefix=$SCHEMA_PREFIX
EOF
fi

echo "Domain configuration file created at: $CONFIG_FILE"
echo "Configuration contents:"
cat "$CONFIG_FILE"

# Prepare log directory and file with correct permissions
LOG_DIR="$INSTALL_FILES_DIR/logs"
LOG_FILE="$LOG_DIR/domain_creation_${DOMAIN_NAME}.log"
mkdir -p "$LOG_DIR"
touch "$LOG_FILE"
chown -R weblogic:weblogic "$LOG_DIR"
chmod 775 "$LOG_DIR"
chmod 664 "$LOG_FILE"

# Set permissions for config file
chown weblogic:weblogic "$CONFIG_FILE"
chmod 644 "$CONFIG_FILE"

# Create domain using config wizard
echo "Running Configuration Wizard..."
echo "Logging output to: $LOG_FILE"

# First verify the config wizard exists
if [ ! -f "$ORACLE_HOME/oracle_common/common/bin/config.sh" ]; then
    echo "Error: Configuration Wizard not found at $ORACLE_HOME/oracle_common/common/bin/config.sh"
    echo "Please ensure WebLogic installation was successful"
    exit 1
fi

# Verify template exists
if [ ! -f "$WLS_HOME/common/templates/wls/wls.jar" ]; then
    echo "Error: Domain template not found at $WLS_HOME/common/templates/wls/wls.jar"
    # Try to find the correct template
    echo "Searching for domain template..."
    TEMPLATE_PATH=$(find $ORACLE_HOME -name "wls.jar" -type f | grep "/common/templates/wls/" | head -1)
    if [ -n "$TEMPLATE_PATH" ]; then
        echo "Found template at: $TEMPLATE_PATH"
        # Update the config file with the correct path
        sed -i "s|DOMAIN_TEMPLATE=.*|DOMAIN_TEMPLATE=$TEMPLATE_PATH|g" "$CONFIG_FILE"
        sed -i "s|CONFIGURATION_TEMPLATE=.*|CONFIGURATION_TEMPLATE=$TEMPLATE_PATH|g" "$CONFIG_FILE"
    else
        echo "No domain template found. WebLogic installation may be incomplete."
        exit 1
    fi
fi

# Execute domain creation with direct output capture
echo "Starting domain creation..."
su - weblogic -c "export JAVA_HOME=$JAVA_HOME && \
    export PATH=$JAVA_HOME/bin:$PATH && \
    export MW_HOME=$MW_HOME && \
    export ORACLE_HOME=$ORACLE_HOME && \
    $ORACLE_HOME/oracle_common/common/bin/config.sh -silent -responseFile=$CONFIG_FILE" > "$LOG_FILE" 2>&1

# Also try with WLST if config.sh fails
if [ $? -ne 0 ]; then
    echo "Configuration Wizard failed, trying WLST..."
    su - weblogic -c "export JAVA_HOME=$JAVA_HOME && \
        export PATH=$JAVA_HOME/bin:$PATH && \
        export MW_HOME=$MW_HOME && \
        export ORACLE_HOME=$ORACLE_HOME && \
        $ORACLE_HOME/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning <<EOF
readTemplate('$WLS_HOME/common/templates/wls/wls.jar')
setOption('DomainName', '$DOMAIN_NAME')
setOption('ServerStartMode', 'prod')
setOption('JavaHome', '$JAVA_HOME')
cd('/Security/base_domain/User/weblogic')
cmo.setPassword('$ADMIN_PASSWORD')
setOption('NodeManagerType', 'PerDomainNodeManager')
setOption('NodeManagerUsername', '$ADMIN_USER')
setOption('NodeManagerPassword', '$ADMIN_PASSWORD')
writeDomain('$DOMAIN_HOME/$DOMAIN_NAME')
closeTemplate()
exit()
EOF" >> "$LOG_FILE" 2>&1
fi

# Check the result and show log if failed
DOMAIN_CREATE_STATUS=$?
if [ $DOMAIN_CREATE_STATUS -ne 0 ]; then
    echo "Domain creation failed. Log contents:"
    echo "----------------------------------------"
    cat "$LOG_FILE"
    echo "----------------------------------------"
    echo "Full log available at: $LOG_FILE"
    
    # Print debug information
    echo "Debug Information:"
    echo "WebLogic Home: $WLS_HOME"
    echo "Template Path: $WLS_HOME/common/templates/wls/wls.jar"
    echo "Domain Path: $DOMAIN_HOME/$DOMAIN_NAME"
    ls -l "$WLS_HOME/common/templates/wls/wls.jar"
    echo "Configuration file contents:"
    cat "$CONFIG_FILE"
    exit 1
fi

# Verify domain was created
if [ ! -d "$DOMAIN_HOME/$DOMAIN_NAME" ]; then
    echo "Domain directory was not created at: $DOMAIN_HOME/$DOMAIN_NAME"
    echo "Check the log file for details: $LOG_FILE"
    exit 1
fi

if [ ! -f "$DOMAIN_HOME/$DOMAIN_NAME/bin/startWebLogic.sh" ]; then
    echo "startWebLogic.sh script not found in: $DOMAIN_HOME/$DOMAIN_NAME/bin/"
    echo "Domain creation may have failed. Check the log file: $LOG_FILE"
    exit 1
fi

# Ensure proper ownership of the domain
echo "Setting correct permissions on domain directory..."
chown -R weblogic:weblogic "$DOMAIN_HOME/$DOMAIN_NAME"
chmod -R 750 "$DOMAIN_HOME/$DOMAIN_NAME"
find "$DOMAIN_HOME/$DOMAIN_NAME/bin" -name "*.sh" -exec chmod 755 {} \;

# Verify permissions are set correctly
if [ $? -eq 0 ]; then
    echo "Domain $DOMAIN_NAME created successfully"
    echo "Domain location: $DOMAIN_HOME/$DOMAIN_NAME"
    echo "To start the WebLogic Server:"
    echo "1. Switch to weblogic user:"
    echo "   sudo su - weblogic"
    echo "2. Start the server:"
    echo "   $DOMAIN_HOME/$DOMAIN_NAME/bin/startWebLogic.sh"
    echo ""
    echo "Once started:"
    echo "- Admin console will be available at: http://localhost:$PORT/console"
    echo "- Admin credentials: $ADMIN_USER/$ADMIN_PASSWORD"
    echo ""
    echo "Note: Always start and stop WebLogic as the 'weblogic' user"
else
    echo "Domain creation failed"
    exit 1
fi
