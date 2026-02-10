#!/bin/bash
set -e

echo "=== Installing Dependencies for Java + Angular Deployment ==="

# Install Java 17 (Amazon Corretto)
echo "Installing Java 17..."
if ! command -v java &> /dev/null; then
    sudo yum install -y java-17-amazon-corretto
fi

java -version

# Install Nginx for Angular frontend
echo "Installing Nginx..."
if ! command -v nginx &> /dev/null; then
    sudo amazon-linux-extras install -y nginx1
    sudo systemctl enable nginx
fi

nginx -v

echo "=== Dependencies installed successfully ==="
