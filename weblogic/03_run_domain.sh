#!/bin/bash

# WebLogic Domain Start Script
# This script starts a WebLogic domain and monitors its status

# Default environment variables
export ORACLE_BASE="/opt/oracle"
export ORACLE_HOME="$ORACLE_BASE/middleware"
export MW_HOME="$ORACLE_HOME"
export WLS_HOME="$MW_HOME/wlserver"
export DOMAIN_HOME="$MW_HOME/user_projects/domains"

# Default values that can be overridden
export DOMAIN_NAME=${1:-"test_domain"}
export ADMIN_URL="http://localhost:7001/console"
export MAX_WAIT_SECONDS=300  # 5 minutes timeout

# Check if running as root (which we don't want)
if [ "$EUID" -eq 0 ]; then 
    echo "This script should NOT be run as root"
    echo "Please run as the weblogic user:"
    echo "su - weblogic -c '$0 $*'"
    exit 1
fi

# Check if running as weblogic user
if [ "$(id -un)" != "weblogic" ]; then
    echo "This script must be run as the weblogic user"
    echo "Please run:"
    echo "su - weblogic -c '$0 $*'"
    exit 1
fi

# Check if WebLogic is installed
if [ ! -d "$WLS_HOME" ]; then
    echo "Error: WebLogic installation not found at $WLS_HOME"
    echo "Please run 01_set_weblogic.sh first to install WebLogic"
    exit 1
fi

# Check if domain exists
if [ ! -d "$DOMAIN_HOME/$DOMAIN_NAME" ]; then
    echo "Error: Domain $DOMAIN_NAME not found at $DOMAIN_HOME/$DOMAIN_NAME"
    echo "Please run 02_set_domain.sh first to create the domain"
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

# Function to check if server is running
check_server_status() {
    local timeout=$1
    local start_time=$(date +%s)
    local status_url="http://localhost:7001/console"

    echo "Waiting for WebLogic Server to start (timeout: ${timeout}s)..."
    
    while true; do
        # Check if the process is running
        if ! pgrep -f "weblogic.Server" > /dev/null; then
            echo "WebLogic process not found"
            return 1
        fi

        # Try to connect to the server
        if curl -s -m 5 "$status_url" > /dev/null; then
            echo "WebLogic Server is running and accessible"
            return 0
        fi

        # Check timeout
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        if [ $elapsed -ge $timeout ]; then
            echo "Timeout waiting for WebLogic Server to start"
            return 1
        fi

        sleep 5
    done
}

# Function to start Node Manager
start_node_manager() {
    echo "Starting Node Manager..."
    if [ -f "$DOMAIN_HOME/$DOMAIN_NAME/bin/startNodeManager.sh" ]; then
        nohup "$DOMAIN_HOME/$DOMAIN_NAME/bin/startNodeManager.sh" > "$DOMAIN_HOME/$DOMAIN_NAME/nodemanager/nodemanager.out" 2>&1 &
        sleep 5
    else
        echo "Warning: Node Manager script not found"
    fi
}

# Function to tail logs
tail_server_logs() {
    local log_file="$DOMAIN_HOME/$DOMAIN_NAME/servers/AdminServer/logs/AdminServer.log"
    if [ -f "$log_file" ]; then
        tail -f "$log_file"
    fi
}

# Start the server
echo "Starting WebLogic Domain: $DOMAIN_NAME"
echo "Domain Path: $DOMAIN_HOME/$DOMAIN_NAME"

# Start Node Manager first
start_node_manager

# Start WebLogic in background
echo "Starting WebLogic Server..."
nohup "$DOMAIN_HOME/$DOMAIN_NAME/bin/startWebLogic.sh" > "$DOMAIN_HOME/$DOMAIN_NAME/servers/AdminServer/logs/startup.log" 2>&1 &

# Check server status
if check_server_status $MAX_WAIT_SECONDS; then
    echo "============================================"
    echo "WebLogic Server started successfully"
    echo "Admin Console URL: $ADMIN_URL"
    echo "Server Log: $DOMAIN_HOME/$DOMAIN_NAME/servers/AdminServer/logs/AdminServer.log"
    echo "Startup Log: $DOMAIN_HOME/$DOMAIN_NAME/servers/AdminServer/logs/startup.log"
    echo "============================================"
    
    # Ask if user wants to tail the logs
    read -p "Would you like to tail the server logs? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        tail_server_logs
    fi
else
    echo "Failed to start WebLogic Server"
    echo "Please check the logs:"
    echo "Startup Log: $DOMAIN_HOME/$DOMAIN_NAME/servers/AdminServer/logs/startup.log"
    echo "Server Log: $DOMAIN_HOME/$DOMAIN_NAME/servers/AdminServer/logs/AdminServer.log"
    exit 1
fi
