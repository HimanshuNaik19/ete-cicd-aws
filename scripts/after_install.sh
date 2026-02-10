#!/bin/bash
# After Install Script for CodeDeploy
# This script runs after files are copied to install npm dependencies

set -e

# Setup logging
LOGFILE="/var/log/codedeploy/after_install.log"
mkdir -p /var/log/codedeploy
exec > >(tee -a "$LOGFILE") 2>&1
echo "[$(date)] Starting AfterInstall script"

echo "=== Installing application dependencies ==="

# Navigate to application directory
cd /home/ec2-user/app

# Install production dependencies only
echo "Installing npm packages..."
npm install --production

# Set proper ownership
chown -R ec2-user:ec2-user /home/ec2-user/app

echo "=== Dependencies installed successfully ==="
