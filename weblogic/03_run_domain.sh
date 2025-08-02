#!/bin/bash

# WebLogic Domain Start Script - Simplified Version
# This script starts a WebLogic domain

# Set environment variables
export ORACLE_BASE="/opt/oracle"
export ORACLE_HOME="$ORACLE_BASE/middleware"
export WLS_HOME="$ORACLE_HOME/wlserver"
export DOMAIN_HOME="$ORACLE_HOME/user_projects/domains"
export DOMAIN_NAME=${1:-"test_domain"}
export ADMIN_PORT="7001"

# Find Java installation
if [ -d "/usr/java/latest" ]; then
    export JAVA_HOME=/usr/java/latest
elif [ -d "/usr/lib/jvm/java-1.8.0" ]; then
    export JAVA_HOME=/usr/lib/jvm/java-1.8.0
else
    echo "Error: Java installation not found"
    exit 1
fi

# Check if running as weblogic user
if [ "$(id -un)" != "weblogic" ]; then
    echo "Error: This script must be run as the weblogic user"
    echo "Run: sudo su - weblogic"
    exit 1
fi

# Check if WebLogic is installed
if [ ! -d "$WLS_HOME" ]; then
    echo "Error: WebLogic installation not found at $WLS_HOME"
    echo "Please run 01_set_weblogic.sh first"
    exit 1
fi

# Check if domain exists
if [ ! -d "$DOMAIN_HOME/$DOMAIN_NAME" ]; then
    echo "Error: Domain $DOMAIN_NAME not found at $DOMAIN_HOME/$DOMAIN_NAME"
    echo "Please run 02_set_domain.sh first"
    exit 1
fi

echo "Starting WebLogic domain: $DOMAIN_NAME"
echo "Domain path: $DOMAIN_HOME/$DOMAIN_NAME"
echo "Admin console will be available at: http://localhost:$ADMIN_PORT/console"

# Check if server is already running
if pgrep -f "weblogic.Server" > /dev/null; then
    echo "WebLogic Server is already running"
    echo "To stop it, run: pkill -f weblogic.Server"
    exit 0
fi

# Start the WebLogic Server
echo "Starting WebLogic Server..."
cd "$DOMAIN_HOME/$DOMAIN_NAME"
exec ./bin/startWebLogic.sh
