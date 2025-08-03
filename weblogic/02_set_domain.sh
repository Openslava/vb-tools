#!/bin/bash

# WebLogic Domain Creation Script - Simplified Version
# This script creates a WebLogic domain with basic configuration
echo "02_set_domain.sh - Starting WebLogic Domain Creation"

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

# Ensure weblogic user has proper permissions to Oracle directories (idempotent)
echo "Setting up permissions for weblogic user..."
if [ -d "$ORACLE_BASE" ]; then
    # Only change ownership if not already owned by weblogic
    if [ "$(stat -c %U "$ORACLE_BASE")" != "weblogic" ]; then
        echo "Setting ownership of $ORACLE_BASE to weblogic..."
        chown -R weblogic:weblogic "$ORACLE_BASE"
    else
        echo "Oracle base already owned by weblogic user"
    fi
    
    # Ensure proper permissions (always safe to run)
    chmod -R 755 "$ORACLE_BASE"
else
    echo "Error: Oracle base directory $ORACLE_BASE not found"
    exit 1
fi

# Get admin password
if [ -z "$ADMIN_PASSWORD" ]; then
    echo -n "Enter WebLogic admin password: "
    read -s ADMIN_PASSWORD
    echo
fi

# Handle existing domain (idempotent)
if [ -d "$DOMAIN_HOME/$DOMAIN_NAME" ]; then
    echo "Domain $DOMAIN_NAME already exists at $DOMAIN_HOME/$DOMAIN_NAME"
    echo -n "Do you want to recreate it? [y/N]: "
    read -r response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            echo "Removing existing domain $DOMAIN_NAME..."
            rm -rf "$DOMAIN_HOME/$DOMAIN_NAME"
            ;;
        *) 
            echo "Keeping existing domain. Exiting."
            exit 0
            ;;
    esac
fi

echo "Creating WebLogic domain: $DOMAIN_NAME"

# Create domain directory with proper permissions (idempotent)
if [ ! -d "$DOMAIN_HOME" ]; then
    echo "Creating domain home directory: $DOMAIN_HOME"
    mkdir -p "$DOMAIN_HOME"
fi

# Set ownership only if needed (idempotent)
if [ "$(stat -c %U "$ORACLE_HOME/user_projects" 2>/dev/null)" != "weblogic" ]; then
    echo "Setting ownership of user_projects to weblogic..."
    chown -R weblogic:weblogic "$ORACLE_HOME/user_projects"
fi
chmod -R 755 "$ORACLE_HOME/user_projects"

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
# Configure Node Manager (but not during domain creation)
setOption('NodeManagerType', 'PerDomainNodeManager')
writeDomain('$DOMAIN_HOME/$DOMAIN_NAME')
closeTemplate()
exit()
EOF

# Create domain
echo "Running WLST to create domain..."
su - weblogic -c "export JAVA_HOME=$JAVA_HOME && $WLS_HOME/../oracle_common/common/bin/wlst.sh /tmp/create_domain.py"

# Clean up temporary script
rm -f /tmp/create_domain.py

# Set final permissions (idempotent)
if [ -d "$DOMAIN_HOME/$DOMAIN_NAME" ]; then
    echo "Setting final permissions on domain $DOMAIN_NAME..."
    chown -R weblogic:weblogic "$DOMAIN_HOME/$DOMAIN_NAME"
    chmod -R 750 "$DOMAIN_HOME/$DOMAIN_NAME"
    
    echo "Domain $DOMAIN_NAME created successfully!"
    echo "Domain location: $DOMAIN_HOME/$DOMAIN_NAME"
    echo "Admin console: http://localhost:$PORT/console"
    echo "To start: su - weblogic -c '$DOMAIN_HOME/$DOMAIN_NAME/bin/startWebLogic.sh'"
else
    echo "Error: Domain creation failed - domain directory not found"
    exit 1
fi
