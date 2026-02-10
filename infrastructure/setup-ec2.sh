#!/bin/bash
# EC2 Instance Setup Script
# This script launches an EC2 instance configured for CodeDeploy

set -e

# Configuration
INSTANCE_TYPE="${INSTANCE_TYPE:-t2.micro}"
REGION="${AWS_REGION:-us-east-1}"
KEY_NAME="${KEY_NAME:-my-key-pair}"
AMI_ID="${AMI_ID:-ami-0c55b159cbfafe1f0}"  # Amazon Linux 2 AMI (update for your region)

echo "=== Launching EC2 Instance for CI/CD Pipeline ==="
echo "Instance Type: $INSTANCE_TYPE"
echo "Region: $REGION"
echo "Key Pair: $KEY_NAME"

# Create security group
SG_NAME="cicd-app-sg-$(date +%s)"
echo "Creating security group: $SG_NAME"

SG_ID=$(aws ec2 create-security-group \
    --group-name "$SG_NAME" \
    --description "Security group for CI/CD application" \
    --region "$REGION" \
    --output text \
    --query 'GroupId')

echo "✓ Security group created: $SG_ID"

# Add inbound rules
echo "Configuring security group rules..."

# Allow HTTP (port 80)
aws ec2 authorize-security-group-ingress \
    --group-id "$SG_ID" \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0 \
    --region "$REGION"

# Allow HTTPS (port 443)
aws ec2 authorize-security-group-ingress \
    --group-id "$SG_ID" \
    --protocol tcp \
    --port 443 \
    --cidr 0.0.0.0/0 \
    --region "$REGION"

# Allow SSH (port 22) - restrict this in production!
aws ec2 authorize-security-group-ingress \
    --group-id "$SG_ID" \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0 \
    --region "$REGION"

# Allow application port (3000)
aws ec2 authorize-security-group-ingress \
    --group-id "$SG_ID" \
    --protocol tcp \
    --port 3000 \
    --cidr 0.0.0.0/0 \
    --region "$REGION"

echo "✓ Security group rules configured"

# Create IAM instance profile (assumes role already exists)
ROLE_NAME="EC2-CodeDeploy-Role"
PROFILE_NAME="EC2-CodeDeploy-Profile"

echo "Creating IAM instance profile..."

# Check if profile exists
if ! aws iam get-instance-profile --instance-profile-name "$PROFILE_NAME" 2>/dev/null; then
    aws iam create-instance-profile \
        --instance-profile-name "$PROFILE_NAME"
    
    # Add role to profile
    aws iam add-role-to-instance-profile \
        --instance-profile-name "$PROFILE_NAME" \
        --role-name "$ROLE_NAME"
    
    echo "✓ Instance profile created"
    
    # Wait for instance profile to be ready
    echo "Waiting for instance profile to propagate..."
    sleep 10
else
    echo "✓ Instance profile already exists"
fi

# Launch EC2 instance
echo "Launching EC2 instance..."

INSTANCE_ID=$(aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --instance-type "$INSTANCE_TYPE" \
    --key-name "$KEY_NAME" \
    --security-group-ids "$SG_ID" \
    --iam-instance-profile Name="$PROFILE_NAME" \
    --user-data file://infrastructure/user-data.sh \
    --tag-specifications "ResourceType=instance,Tags=[
        {Key=Name,Value=CICD-App-Server},
        {Key=Project,Value=CICD-Pipeline},
        {Key=Environment,Value=Production},
        {Key=DeploymentGroup,Value=Production-Fleet}
    ]" \
    --region "$REGION" \
    --output text \
    --query 'Instances[0].InstanceId')

echo "✓ Instance launched: $INSTANCE_ID"

# Wait for instance to be running
echo "Waiting for instance to be running..."
aws ec2 wait instance-running \
    --instance-ids "$INSTANCE_ID" \
    --region "$REGION"

# Get instance details
INSTANCE_INFO=$(aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --region "$REGION" \
    --query 'Reservations[0].Instances[0].[PublicIpAddress,PrivateIpAddress]' \
    --output text)

PUBLIC_IP=$(echo "$INSTANCE_INFO" | awk '{print $1}')
PRIVATE_IP=$(echo "$INSTANCE_INFO" | awk '{print $2}')

echo ""
echo "=== EC2 Instance Setup Complete ==="
echo "Instance ID: $INSTANCE_ID"
echo "Public IP: $PUBLIC_IP"
echo "Private IP: $PRIVATE_IP"
echo "Security Group: $SG_ID"
echo ""
echo "IMPORTANT: Save these values for CodeDeploy configuration"
echo ""
echo "To SSH into the instance:"
echo "  ssh -i ~/.ssh/$KEY_NAME.pem ec2-user@$PUBLIC_IP"
echo ""
echo "To check CodeDeploy agent status:"
echo "  ssh -i ~/.ssh/$KEY_NAME.pem ec2-user@$PUBLIC_IP 'sudo service codedeploy-agent status'"
