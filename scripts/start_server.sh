#!/bin/bash
set -e

echo "=== Starting Java Application ==="

APP_DIR="/home/ec2-user/app"
JAR_FILE="$APP_DIR/backend/target/cicd-app.jar"

# Check if JAR exists
if [ ! -f "$JAR_FILE" ]; then
    echo "ERROR: JAR file not found at $JAR_FILE"
    exit 1
fi

# Start Spring Boot application with memory limits for t2.micro
echo "Starting Spring Boot application..."
nohup java \
    -Xmx256m \
    -Xms128m \
    -XX:+UseSerialGC \
    -Dserver.port=8080 \
    -jar $JAR_FILE \
    > $APP_DIR/backend.log 2>&1 &

JAVA_PID=$!
echo "Java application started with PID: $JAVA_PID"

# Wait for application to start
echo "Waiting for Spring Boot to start..."
sleep 10

# Check if process is still running
if ps -p $JAVA_PID > /dev/null; then
    echo "Java application is running"
else
    echo "ERROR: Java application failed to start"
    cat $APP_DIR/backend.log
    exit 1
fi

# Start/Restart Nginx
echo "Starting Nginx..."
sudo systemctl restart nginx
sudo systemctl status nginx --no-pager

echo "=== Application started successfully ==="
echo "Backend: http://localhost:8080"
echo "Frontend: http://localhost:80"
