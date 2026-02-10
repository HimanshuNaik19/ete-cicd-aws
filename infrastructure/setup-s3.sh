#!/bin/bash
# S3 Bucket Setup Script for CI/CD Pipeline Artifacts
# This script creates and configures the S3 bucket for storing pipeline artifacts

set -e

# Configuration
BUCKET_NAME="cicd-pipeline-artifacts-$(date +%s)"
REGION="${AWS_REGION:-us-east-1}"

echo "=== Creating S3 Bucket for Pipeline Artifacts ==="
echo "Bucket Name: $BUCKET_NAME"
echo "Region: $REGION"

# Create S3 bucket
if [ "$REGION" = "us-east-1" ]; then
    aws s3api create-bucket \
        --bucket "$BUCKET_NAME" \
        --region "$REGION"
else
    aws s3api create-bucket \
        --bucket "$BUCKET_NAME" \
        --region "$REGION" \
        --create-bucket-configuration LocationConstraint="$REGION"
fi

echo "✓ Bucket created: $BUCKET_NAME"

# Enable versioning
aws s3api put-bucket-versioning \
    --bucket "$BUCKET_NAME" \
    --versioning-configuration Status=Enabled

echo "✓ Versioning enabled"

# Enable server-side encryption
aws s3api put-bucket-encryption \
    --bucket "$BUCKET_NAME" \
    --server-side-encryption-configuration '{
        "Rules": [{
            "ApplyServerSideEncryptionByDefault": {
                "SSEAlgorithm": "AES256"
            }
        }]
    }'

echo "✓ Encryption enabled (AES256)"

# Block public access
aws s3api put-public-access-block \
    --bucket "$BUCKET_NAME" \
    --public-access-block-configuration \
        BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

echo "✓ Public access blocked"

# Add lifecycle policy to clean up old artifacts (optional)
aws s3api put-bucket-lifecycle-configuration \
    --bucket "$BUCKET_NAME" \
    --lifecycle-configuration '{
        "Rules": [{
            "Id": "DeleteOldArtifacts",
            "Status": "Enabled",
            "Prefix": "",
            "NoncurrentVersionExpiration": {
                "NoncurrentDays": 30
            },
            "AbortIncompleteMultipartUpload": {
                "DaysAfterInitiation": 7
            }
        }]
    }'

echo "✓ Lifecycle policy configured (30-day retention)"

# Add tags
aws s3api put-bucket-tagging \
    --bucket "$BUCKET_NAME" \
    --tagging 'TagSet=[
        {Key=Project,Value=CICD-Pipeline},
        {Key=Purpose,Value=Artifacts},
        {Key=ManagedBy,Value=Script}
    ]'

echo "✓ Tags added"

echo ""
echo "=== S3 Bucket Setup Complete ==="
echo "Bucket Name: $BUCKET_NAME"
echo ""
echo "IMPORTANT: Save this bucket name for use in CodePipeline configuration"
echo "Export it as an environment variable:"
echo "  export ARTIFACT_BUCKET=$BUCKET_NAME"
