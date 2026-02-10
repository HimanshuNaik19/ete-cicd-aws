#!/bin/bash
# After Install Script for CodeDeploy
# This script runs after files are copied to install npm dependencies

set -e

echo "=== Installing application dependencies ==="

# Navigate to application directory
cd /home/ec2-user/app

# Install production dependencies only
echo "Installing npm packages..."
npm install --production

# Set proper ownership
chown -R ec2-user:ec2-user /home/ec2-user/app

echo "=== Dependencies installed successfully ==="
