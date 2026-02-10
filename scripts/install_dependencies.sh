#!/bin/bash
# Install Dependencies Script for CodeDeploy
# This script runs as root during the BeforeInstall lifecycle event

set -e

echo "=== Installing Node.js and dependencies ==="

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
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

# Navigate to application directory
cd /home/ec2-user/app

# Install application dependencies
echo "Installing application dependencies..."
npm install --production

# Set proper ownership
chown -R ec2-user:ec2-user /home/ec2-user/app

echo "=== Dependencies installed successfully ==="
