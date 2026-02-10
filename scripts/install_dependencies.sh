#!/bin/bash
# Install Dependencies Script for CodeDeploy
# This script runs as root during the BeforeInstall lifecycle event

set -e

# Setup logging
LOGFILE="/var/log/codedeploy/install_dependencies.log"
mkdir -p /var/log/codedeploy
exec > >(tee -a "$LOGFILE") 2>&1
echo "[$(date)] Starting BeforeInstall script"

echo "=== Installing Node.js ==="

# Check if Node.js is installed
if ! command -v node &gt; /dev/null; then
    echo "Node.js not found. Installing Node.js 14.x..."
    
    # Install Node.js 14.x on Amazon Linux 2
    curl -sL https://rpm.nodesource.com/setup_14.x | bash -
    yum install -y nodejs
    
    echo "Node.js installed successfully"
    node --version
    npm --version
else
    echo "Node.js is already installed"
    node --version
fi

# Create application directory if it doesn't exist
echo "Creating application directory..."
mkdir -p /home/ec2-user/app

# Set proper ownership
chown -R ec2-user:ec2-user /home/ec2-user/app

echo "=== Node.js setup complete ==="
