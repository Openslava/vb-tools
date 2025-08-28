#!/bin/bash
# Start WebLogic domain
# set -e

echo "🚀 Starting WebLogic domain..."

# Environment setup
export ORACLE_BASE="/opt/oracle"
export DOMAIN_HOME="$ORACLE_BASE/middleware/user_projects/domains"
export DOMAIN_NAME=${1:-"test_domain"}
export ADMIN_PORT="7001"

# Switch to weblogic user if running as root
if [ "$(id -un)" != "weblogic" ] && [ "$EUID" -eq 0 ]; then
    echo "👤 Switching to weblogic user..."
    exec su - weblogic -c "$(readlink -f "$0") $*"
fi

# Check domain exists
if [ ! -d "$DOMAIN_HOME/$DOMAIN_NAME" ]; then
    echo "❌ Domain $DOMAIN_NAME not found"
    exit 1
fi

# Check if already running
if pgrep -f "Dweblogic.Name=AdminServer.*$DOMAIN_NAME" >/dev/null; then
    echo "✅ Domain $DOMAIN_NAME already running"
    echo "🌐 Console: http://localhost:$ADMIN_PORT/console"
    exit 0
fi

# Start WebLogic
echo "🔧 Starting domain $DOMAIN_NAME..."
cd "$DOMAIN_HOME/$DOMAIN_NAME"
echo "🌐 Admin console will be at: http://localhost:$ADMIN_PORT/console"
exec ./bin/startWebLogic.sh
