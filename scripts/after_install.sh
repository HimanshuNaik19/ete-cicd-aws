#!/bin/bash
set -e

echo "=== Configuring Nginx and Deploying Frontend ==="

APP_DIR="/home/ec2-user/app"

# Copy Nginx configuration
echo "Setting up Nginx configuration..."
sudo cp $APP_DIR/nginx/nginx.conf /etc/nginx/conf.d/app.conf

# Deploy Angular frontend
echo "Deploying Angular frontend..."
sudo rm -rf /usr/share/nginx/html/*
sudo cp -r $APP_DIR/frontend/dist/frontend/browser/* /usr/share/nginx/html/ 2>/dev/null || \
sudo cp -r $APP_DIR/frontend/dist/frontend/* /usr/share/nginx/html/

# Set permissions
sudo chown -R nginx:nginx /usr/share/nginx/html/
sudo chmod -R 755 /usr/share/nginx/html/

# Test Nginx configuration
sudo nginx -t

echo "=== Nginx configuration complete ==="
