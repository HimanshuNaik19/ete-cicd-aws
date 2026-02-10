#!/bin/bash
# Stop Server Script for CodeDeploy
# This script runs during the ApplicationStop lifecycle event

set -e

echo "=== Stopping application server ==="

# Check if the application is running
if pgrep -f "node.*app.js" > /dev/null; then
    echo "Application is running. Stopping..."
    
    # Get the process ID
    PID=$(pgrep -f "node.*app.js")
    
    # Send SIGTERM for graceful shutdown
    kill -SIGTERM $PID
    
    # Wait for process to stop (max 30 seconds)
    for i in {1..30}; do
        if ! pgrep -f "node.*app.js" > /dev/null; then
            echo "Application stopped gracefully"
            exit 0
        fi
        sleep 1
    done
    
    # Force kill if still running
    if pgrep -f "node.*app.js" > /dev/null; then
        echo "Forcing application to stop..."
        kill -9 $PID
    fi
    
    echo "Application stopped"
else
    echo "Application is not running. Nothing to stop."
fi

echo "=== Stop script completed ==="
