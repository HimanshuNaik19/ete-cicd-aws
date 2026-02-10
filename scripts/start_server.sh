#!/bin/bash
# Start Server Script for CodeDeploy
# This script runs during the ApplicationStart lifecycle event

set -e

echo "=== Starting application server ==="

# Navigate to application directory
cd /home/ec2-user/app

# Set environment variables
export NODE_ENV=production
export PORT=3000

# Start the application in the background
nohup node app.js > /home/ec2-user/app/app.log 2>&1 &

# Get the process ID
PID=$!

echo "Application started with PID: $PID"

# Wait a moment for the application to start
sleep 5

# Verify the process is still running
if ps -p $PID > /dev/null; then
    echo "Application is running successfully"
    echo $PID > /home/ec2-user/app/app.pid
else
    echo "ERROR: Application failed to start"
    cat /home/ec2-user/app/app.log
    exit 1
fi

echo "=== Start script completed ==="
