#!/bin/bash
set -e

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
export ADMIN_USER=${ADMIN_USER:-"admin"}

# Generate a secure random password if not provided
if [ -z "$ADMIN_PASSWORD" ]; then
    # Generate random password: 12 chars with uppercase, lowercase, numbers, and symbols
    export ADMIN_PASSWORD=$(openssl rand -base64 12 | tr -d "=+/" | cut -c1-12)$(date +%N | cut -c1-6)
    # Ensure it meets WebLogic password requirements (8+ chars, mix of case/numbers)
    export ADMIN_PASSWORD="Wls${ADMIN_PASSWORD}!"
fi

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
if [ "$EUID" -ne 0 ]; then  echo "Please run as root or with sudo";  exit 1; fi

# Check if WebLogic is installed
if [ ! -d "$WLS_HOME" ]; then echo "Error: WebLogic installation not found at $WLS_HOME"; exit 2; fi

# Ensure weblogic user has proper permissions to Oracle directories
echo "Setting up permissions for weblogic user..."
if [ -d "$ORACLE_BASE" ]; then
    echo "Setting ownership of $ORACLE_BASE to weblogic..."
    chown -R weblogic:weblogic "$ORACLE_BASE"
    chmod -R 755 "$ORACLE_BASE"
else
    echo "Error: Oracle base directory $ORACLE_BASE not found"
    exit 1
fi

# Handle existing domain (force mode or idempotent behavior)
if [ -d "$DOMAIN_HOME/$DOMAIN_NAME" ]; then
    if [ "$FORCE_MODE" = "true" ]; then
        echo "Force mode enabled - removing existing domain: $DOMAIN_HOME/$DOMAIN_NAME"
        rm -rf "$DOMAIN_HOME/$DOMAIN_NAME"
        echo "Existing domain removed, will recreate with new password"
    else
        echo "Domain $DOMAIN_NAME already exists at $DOMAIN_HOME/$DOMAIN_NAME"
        echo "Skipping creation. To recreate: use -forse parameter or manually run: rm -rf '$DOMAIN_HOME/$DOMAIN_NAME'"
        exit 0
    fi
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
# WLST script to create WebLogic domain
print('Creating domain with name: $DOMAIN_NAME')
print('Using WebLogic admin user: $ADMIN_USER')
print('Admin password length: ${#ADMIN_PASSWORD}')

readTemplate('$WLS_HOME/common/templates/wls/wls.jar')
setOption('DomainName', '$DOMAIN_NAME')
setOption('ServerStartMode', 'prod')
setOption('JavaHome', '$JAVA_HOME')

# Set admin user password - note: this is the WebLogic admin user, not the Linux user
# The default WebLogic admin user in the template is 'weblogic', but we want to use our admin user
cd('/Security/base_domain/User/weblogic')
set('Name', '$ADMIN_USER')
cmo.setPassword('$ADMIN_PASSWORD')

# Configure AdminServer
cd('/Servers/AdminServer')
set('ListenPort', $PORT)

# Configure Node Manager
setOption('NodeManagerType', 'PerDomainNodeManager')

# Write domain
print('Writing domain to: $DOMAIN_HOME/$DOMAIN_NAME')
writeDomain('$DOMAIN_HOME/$DOMAIN_NAME')
closeTemplate()

print('Domain creation completed successfully')
print('WebLogic admin user: $ADMIN_USER (runs as Linux user: weblogic)')
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
    echo ""
    echo "=== WebLogic Admin Console Access ==="
    echo "URL: http://localhost:$PORT/console"
    echo "Username: $ADMIN_USER"
    echo "Password: $ADMIN_PASSWORD"
    echo ""
    echo "IMPORTANT: Save the password above - you'll need it to access the console!"
    echo "Source environment: sudo su - weblogic -c 'source $DOMAIN_HOME/$DOMAIN_NAME/bin/setDomainEnv.sh'"
    echo "To start: sudo su - weblogic -c '$DOMAIN_HOME/$DOMAIN_NAME/bin/startWebLogic.sh'"
    echo "To stop:  sudo su - weblogic -c '$DOMAIN_HOME/$DOMAIN_NAME/bin/stopWebLogic.sh'"
else
    echo "Error: Domain creation failed - domain directory not found"
    exit 1
fi
