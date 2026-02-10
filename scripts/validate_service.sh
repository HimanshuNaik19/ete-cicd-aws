#!/bin/bash
# Validate Service Script for CodeDeploy
# This script runs during the ValidateService lifecycle event

set -e

echo "=== Validating application deployment ==="

# Wait for application to be fully ready
sleep 10

# Check if the process is running
if ! pgrep -f "node.*app.js" > /dev/null; then
    echo "ERROR: Application process is not running"
    exit 1
fi

echo "✓ Application process is running"

# Test the health endpoint
MAX_RETRIES=10
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/health || echo "000")
    
    if [ "$HTTP_CODE" = "200" ]; then
        echo "✓ Health check passed (HTTP $HTTP_CODE)"
        
        # Test the main endpoint
        RESPONSE=$(curl -s http://localhost:3000/)
        echo "✓ Application response: $RESPONSE"
        
        echo "=== Validation completed successfully ==="
        exit 0
    fi
    
    echo "Health check failed (HTTP $HTTP_CODE). Retrying in 3 seconds... ($((RETRY_COUNT + 1))/$MAX_RETRIES)"
    sleep 3
    RETRY_COUNT=$((RETRY_COUNT + 1))
done

echo "ERROR: Health check failed after $MAX_RETRIES attempts"
echo "Application logs:"
tail -n 50 /home/ec2-user/app/app.log

exit 1
