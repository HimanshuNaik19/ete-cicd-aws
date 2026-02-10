#!/bin/bash
set -e

echo "=== Stopping Java Application ==="

# Find and kill Java process
JAVA_PID=$(pgrep -f "java.*cicd-app.jar" || echo "")

if [ -n "$JAVA_PID" ]; then
    echo "Stopping Java application (PID: $JAVA_PID)..."
    kill $JAVA_PID || true
    sleep 3
    
    # Force kill if still running
    if ps -p $JAVA_PID > /dev/null 2>&1; then
        echo "Force killing Java application..."
        kill -9 $JAVA_PID || true
    fi
    
    echo "Java application stopped"
else
    echo "No Java application running"
fi

echo "=== Stop complete ==="
