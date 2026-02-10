#!/bin/bash
set -e

echo "=== Validating Service Deployment ==="

MAX_RETRIES=12
RETRY_DELAY=5

# Function to check endpoint
check_endpoint() {
    local url=$1
    local name=$2
    
    echo "Checking $name at $url..."
    
    for i in $(seq 1 $MAX_RETRIES); do
        if curl -f -s -o /dev/null -w "%{http_code}" $url | grep -q "200"; then
            echo "✓ $name is responding (attempt $i/$MAX_RETRIES)"
            return 0
        fi
        
        echo "Waiting for $name... (attempt $i/$MAX_RETRIES)"
        sleep $RETRY_DELAY
    done
    
    echo "✗ $name failed to respond after $MAX_RETRIES attempts"
    return 1
}

# Check backend (Spring Boot)
if ! check_endpoint "http://localhost:8080/health" "Backend API"; then
    echo "Backend logs:"
    tail -50 /home/ec2-user/app/backend.log
    exit 1
fi

# Check frontend (Nginx)
if ! check_endpoint "http://localhost:80" "Frontend (Nginx)"; then
    echo "Nginx logs:"
    sudo tail -50 /var/log/nginx/error.log
    exit 1
fi

# Additional health check
echo "Performing detailed health check..."
HEALTH_RESPONSE=$(curl -s http://localhost:8080/health)
echo "Health response: $HEALTH_RESPONSE"

if echo "$HEALTH_RESPONSE" | grep -q "healthy"; then
    echo "✓ Application is healthy"
else
    echo "✗ Application health check failed"
    exit 1
fi

echo "=== Validation successful ==="
echo "Application is running and healthy!"
