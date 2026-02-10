# AWS CI/CD Pipeline Setup Guide

This guide provides step-by-step instructions to set up a complete CI/CD pipeline using AWS CodePipeline, CodeBuild, and CodeDeploy.

## Prerequisites

- AWS Account with appropriate permissions
- AWS CLI installed and configured
- GitHub account and repository
- SSH key pair for EC2 access
- Basic knowledge of AWS services

## Architecture Overview

```
GitHub → CodePipeline → CodeBuild → S3 Artifacts → CodeDeploy → EC2
```

---

## Step 1: Create IAM Roles

### 1.1 CodePipeline Service Role

```bash
# Create the role
aws iam create-role \
  --role-name CodePipeline-Service-Role \
  --assume-role-policy-document file://iam/codepipeline-trust-policy.json

# Attach the policy
aws iam put-role-policy \
  --role-name CodePipeline-Service-Role \
  --policy-name CodePipeline-Policy \
  --policy-document file://iam/codepipeline-policy.json
```

### 1.2 CodeBuild Service Role

```bash
# Create the role
aws iam create-role \
  --role-name CodeBuild-Service-Role \
  --assume-role-policy-document file://iam/codebuild-trust-policy.json

# Attach the policy
aws iam put-role-policy \
  --role-name CodeBuild-Service-Role \
  --policy-name CodeBuild-Policy \
  --policy-document file://iam/codebuild-policy.json
```

### 1.3 CodeDeploy Service Role

```bash
# Create the role
aws iam create-role \
  --role-name CodeDeploy-Service-Role \
  --assume-role-policy-document file://iam/codedeploy-trust-policy.json

# Attach the policy
aws iam put-role-policy \
  --role-name CodeDeploy-Service-Role \
  --policy-name CodeDeploy-Policy \
  --policy-document file://iam/codedeploy-policy.json
```

### 1.4 EC2 Instance Profile

```bash
# Create the role
aws iam create-role \
  --role-name EC2-CodeDeploy-Role \
  --assume-role-policy-document file://iam/ec2-trust-policy.json

# Attach the policy
aws iam put-role-policy \
  --role-name EC2-CodeDeploy-Role \
  --policy-name EC2-Instance-Policy \
  --policy-document file://iam/ec2-instance-policy.json

# Create instance profile
aws iam create-instance-profile \
  --instance-profile-name EC2-CodeDeploy-Profile

# Add role to instance profile
aws iam add-role-to-instance-profile \
  --instance-profile-name EC2-CodeDeploy-Profile \
  --role-name EC2-CodeDeploy-Role
```

---

## Step 2: Create S3 Bucket for Artifacts

Run the automated setup script:

```bash
chmod +x infrastructure/setup-s3.sh
./infrastructure/setup-s3.sh
```

Or manually create the bucket:

```bash
# Set your bucket name (must be globally unique)
BUCKET_NAME="cicd-pipeline-artifacts-$(date +%s)"

# Create bucket
aws s3api create-bucket \
  --bucket "$BUCKET_NAME" \
  --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket "$BUCKET_NAME" \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket "$BUCKET_NAME" \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'
```

**Save the bucket name** - you'll need it for later steps.

---

## Step 3: Launch EC2 Instance

### 3.1 Update Configuration

Edit `infrastructure/setup-ec2.sh` and update:
- `KEY_NAME` - your EC2 key pair name
- `AMI_ID` - Amazon Linux 2 AMI for your region
- `REGION` - your AWS region

### 3.2 Run Setup Script

```bash
chmod +x infrastructure/setup-ec2.sh
./infrastructure/setup-ec2.sh
```

### 3.3 Verify CodeDeploy Agent

SSH into the instance and check:

```bash
ssh -i ~/.ssh/YOUR_KEY.pem ec2-user@YOUR_INSTANCE_IP
sudo service codedeploy-agent status
```

You should see: "The AWS CodeDeploy agent is running"

---

## Step 4: Set Up GitHub Connection

### 4.1 Create CodeStar Connection

```bash
aws codestar-connections create-connection \
  --provider-type GitHub \
  --connection-name github-connection
```

### 4.2 Complete Authorization

1. Go to AWS Console → Developer Tools → Settings → Connections
2. Find your connection and click "Update pending connection"
3. Authorize AWS to access your GitHub account
4. Note the Connection ARN

---

## Step 5: Create CodeBuild Project

Update `aws-config/codebuild-project.json`:
- Replace `ACCOUNT_ID` with your AWS account ID
- Replace `ARTIFACT_BUCKET` with your S3 bucket name

Create the project:

```bash
aws codebuild create-project \
  --cli-input-json file://aws-config/codebuild-project.json
```

---

## Step 6: Create CodeDeploy Application

### 6.1 Create Application

```bash
aws deploy create-application \
  --application-name CICD-Demo-App \
  --compute-platform Server
```

### 6.2 Create Deployment Group

Update `aws-config/codedeploy-application.json`:
- Replace `ACCOUNT_ID` with your AWS account ID

Create the deployment group:

```bash
aws deploy create-deployment-group \
  --cli-input-json file://aws-config/codedeploy-application.json
```

---

## Step 7: Create CodePipeline

Update `aws-config/codepipeline.json`:
- Replace `ACCOUNT_ID` with your AWS account ID
- Replace `REGION` with your AWS region
- Replace `CONNECTION_ID` with your CodeStar connection ID
- Replace `ARTIFACT_BUCKET_NAME` with your S3 bucket name
- Replace `YOUR_GITHUB_USERNAME` with your GitHub username

Create the pipeline:

```bash
aws codepipeline create-pipeline \
  --cli-input-json file://aws-config/codepipeline.json
```

---

## Step 8: Push Code to GitHub

### 8.1 Initialize Git Repository

```bash
git init
git add .
git commit -m "Initial commit - AWS CI/CD Pipeline"
```

### 8.2 Add Remote and Push

```bash
git remote add origin https://github.com/YOUR_USERNAME/ete-cicd-aws.git
git branch -M main
git push -u origin main
```

---

## Step 9: Monitor Pipeline Execution

### 9.1 AWS Console

1. Go to AWS CodePipeline console
2. Click on "CICD-Demo-Pipeline"
3. Watch the pipeline execute through all stages

### 9.2 AWS CLI

```bash
# Get pipeline status
aws codepipeline get-pipeline-state \
  --name CICD-Demo-Pipeline

# View CodeBuild logs
aws codebuild batch-get-builds \
  --ids <build-id>

# View CodeDeploy deployment
aws deploy get-deployment \
  --deployment-id <deployment-id>
```

---

## Step 10: Verify Deployment

### 10.1 Check Application

```bash
# Get EC2 instance public IP
INSTANCE_IP=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=CICD-App-Server" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

# Test the application
curl http://$INSTANCE_IP:3000
curl http://$INSTANCE_IP:3000/health
curl http://$INSTANCE_IP:3000/api/info
```

Expected response:
```json
{
  "message": "Welcome to AWS CI/CD Pipeline Demo",
  "version": "1.0.0",
  "environment": "production"
}
```

---

## Troubleshooting

### Pipeline Fails at Source Stage
- Verify GitHub connection is authorized
- Check repository name and branch are correct

### Build Stage Fails
- Check CloudWatch Logs for CodeBuild
- Verify buildspec.yml syntax
- Ensure IAM role has necessary permissions

### Deploy Stage Fails
- SSH into EC2 and check CodeDeploy agent: `sudo service codedeploy-agent status`
- Check deployment logs: `tail -f /var/log/aws/codedeploy-agent/codedeploy-agent.log`
- Verify EC2 instance has correct tags
- Ensure IAM instance profile is attached

### Application Not Responding
- Check if Node.js process is running: `ps aux | grep node`
- View application logs: `cat /home/ec2-user/app/app.log`
- Check security group allows traffic on port 3000

---

## Clean Up Resources

To avoid ongoing charges, delete all resources:

```bash
# Delete pipeline
aws codepipeline delete-pipeline --name CICD-Demo-Pipeline

# Delete CodeBuild project
aws codebuild delete-project --name cicd-demo-build-project

# Delete CodeDeploy resources
aws deploy delete-deployment-group \
  --application-name CICD-Demo-App \
  --deployment-group-name Production-Fleet
aws deploy delete-application --application-name CICD-Demo-App

# Terminate EC2 instance
aws ec2 terminate-instances --instance-ids <instance-id>

# Delete S3 bucket (after emptying it)
aws s3 rm s3://BUCKET_NAME --recursive
aws s3api delete-bucket --bucket BUCKET_NAME

# Delete IAM roles and policies
aws iam delete-role-policy --role-name CodePipeline-Service-Role --policy-name CodePipeline-Policy
aws iam delete-role --role-name CodePipeline-Service-Role
# Repeat for other roles...
```

---

## Next Steps

- Add staging environment
- Implement manual approval stage
- Add SNS notifications
- Integrate with CloudWatch alarms
- Add automated rollback on failure
- Implement blue/green deployments
