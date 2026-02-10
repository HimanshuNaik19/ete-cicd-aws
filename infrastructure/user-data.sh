#!/bin/bash
# EC2 User Data Script
# This script runs when the EC2 instance first launches
# It installs the CodeDeploy agent and prepares the instance for deployments

set -e

# Update system packages
yum update -y

# Install Ruby (required for CodeDeploy agent)
yum install -y ruby wget

# Download and install CodeDeploy agent
cd /home/ec2-user
wget https://aws-codedeploy-us-east-1.s3.us-east-1.amazonaws.com/latest/install
chmod +x ./install
./install auto

# Start CodeDeploy agent
service codedeploy-agent start

# Enable CodeDeploy agent to start on boot
chkconfig codedeploy-agent on

# Install Node.js 14.x
curl -sL https://rpm.nodesource.com/setup_14.x | bash -
yum install -y nodejs

# Create application directory
mkdir -p /home/ec2-user/app
chown ec2-user:ec2-user /home/ec2-user/app

# Install CloudWatch agent (optional but recommended)
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm

# Create a simple health check page
cat > /home/ec2-user/health.html <<EOF
<!DOCTYPE html>
<html>
<head><title>Instance Health</title></head>
<body>
<h1>EC2 Instance is Running</h1>
<p>CodeDeploy agent is installed and ready.</p>
</body>
</html>
EOF

echo "EC2 instance initialization complete"
