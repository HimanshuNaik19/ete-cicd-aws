#!/bin/bash
# Setup IAM Roles Script
# This script creates all required IAM roles for the CI/CD pipeline

set -e

echo "=== Creating IAM Roles for CI/CD Pipeline ==="
echo ""

# 1. Create CodePipeline Role
echo "1. Creating CodePipeline Service Role..."
aws iam create-role \
  --role-name CodePipeline-Service-Role \
  --assume-role-policy-document file://iam/codepipeline-trust-policy.json \
  2>/dev/null || echo "  Role already exists, skipping..."

aws iam put-role-policy \
  --role-name CodePipeline-Service-Role \
  --policy-name CodePipeline-Policy \
  --policy-document file://iam/codepipeline-policy.json

echo "  ✓ CodePipeline role created"
echo ""

# 2. Create CodeBuild Role
echo "2. Creating CodeBuild Service Role..."
aws iam create-role \
  --role-name CodeBuild-Service-Role \
  --assume-role-policy-document file://iam/codebuild-trust-policy.json \
  2>/dev/null || echo "  Role already exists, skipping..."

aws iam put-role-policy \
  --role-name CodeBuild-Service-Role \
  --policy-name CodeBuild-Policy \
  --policy-document file://iam/codebuild-policy.json

echo "  ✓ CodeBuild role created"
echo ""

# 3. Create CodeDeploy Role
echo "3. Creating CodeDeploy Service Role..."
aws iam create-role \
  --role-name CodeDeploy-Service-Role \
  --assume-role-policy-document file://iam/codedeploy-trust-policy.json \
  2>/dev/null || echo "  Role already exists, skipping..."

aws iam put-role-policy \
  --role-name CodeDeploy-Service-Role \
  --policy-name CodeDeploy-Policy \
  --policy-document file://iam/codedeploy-policy.json

echo "  ✓ CodeDeploy role created"
echo ""

# 4. Create EC2 Instance Role and Profile
echo "4. Creating EC2 Instance Role and Profile..."
aws iam create-role \
  --role-name EC2-CodeDeploy-Role \
  --assume-role-policy-document file://iam/ec2-trust-policy.json \
  2>/dev/null || echo "  Role already exists, skipping..."

aws iam put-role-policy \
  --role-name EC2-CodeDeploy-Role \
  --policy-name EC2-Instance-Policy \
  --policy-document file://iam/ec2-instance-policy.json

# Create instance profile
aws iam create-instance-profile \
  --instance-profile-name EC2-CodeDeploy-Profile \
  2>/dev/null || echo "  Instance profile already exists, skipping..."

# Add role to instance profile (ignore error if already added)
aws iam add-role-to-instance-profile \
  --instance-profile-name EC2-CodeDeploy-Profile \
  --role-name EC2-CodeDeploy-Role \
  2>/dev/null || echo "  Role already in profile, skipping..."

echo "  ✓ EC2 role and instance profile created"
echo ""

echo "=== IAM Roles Setup Complete ==="
echo ""
echo "Created roles:"
echo "  - CodePipeline-Service-Role"
echo "  - CodeBuild-Service-Role"
echo "  - CodeDeploy-Service-Role"
echo "  - EC2-CodeDeploy-Role (with EC2-CodeDeploy-Profile)"
echo ""
echo "Waiting 10 seconds for IAM roles to propagate..."
sleep 10
echo "✓ Ready to proceed with next steps"
