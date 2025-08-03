#!/bin/bash

# WebLogic Domain Start Script - Simplified Version
# This script starts a WebLogic domain
echo "03_run_domain.sh - Starting WebLogic Domain"

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

# Check if running as weblogic user or if we can switch to weblogic
if [ "$(id -un)" != "weblogic" ]; then
    # Get absolute path of current script to avoid path issues
    SCRIPT_PATH="$(readlink -f "$0")"
    
    # If running as root, try to switch to weblogic user
    if [ "$EUID" -eq 0 ]; then
        echo "Running as root, switching to weblogic user..."
        exec su - weblogic -c "$SCRIPT_PATH $*"
    else
        echo "Error: This script must be run as the weblogic user or as root"
        echo "Run: sudo su - weblogic -c '$SCRIPT_PATH $*'"
        echo "Or: sudo $SCRIPT_PATH $*"
        exit 1
    fi
fi

echo "Running as weblogic user: $(id -un)"

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

# Check if server is already running (idempotent)
DOMAIN_PID=$(pgrep -f "Dweblogic.Name=AdminServer.*$DOMAIN_NAME" 2>/dev/null)
if [ -n "$DOMAIN_PID" ]; then
    echo "WebLogic AdminServer for domain '$DOMAIN_NAME' is already running (PID: $DOMAIN_PID)"
    echo "Admin console: http://localhost:$ADMIN_PORT/console"
    echo "To stop it, run: kill $DOMAIN_PID"
    echo "Or use: $DOMAIN_HOME/$DOMAIN_NAME/bin/stopWebLogic.sh"
    exit 0
fi

# Check for any WebLogic processes
if pgrep -f "weblogic.Server" > /dev/null; then
    echo "Warning: Other WebLogic Server processes are running"
    pgrep -f "weblogic.Server" | while read pid; do
        echo "  PID $pid: $(ps -p $pid -o args --no-headers)"
    done
    echo ""
fi

# Start the WebLogic Server
echo "Starting WebLogic Server..."
cd "$DOMAIN_HOME/$DOMAIN_NAME"
exec ./bin/startWebLogic.sh
