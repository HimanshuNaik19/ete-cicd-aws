# Fresh Start Guide - AWS CI/CD Pipeline Setup

## Step 1: Add Permissions to terraform-aws-user

### Option A: Attach AWS Managed Policies (Easiest)

Go to **IAM Console** → **Users** → `terraform-aws-user` → **Add permissions**

Attach these AWS managed policies:
- ✅ `IAMFullAccess`
- ✅ `AmazonS3FullAccess`
- ✅ `AWSCodeBuildAdminAccess`
- ✅ `AWSCodeDeployFullAccess`
- ✅ `AWSCodePipeline_FullAccess`
- ✅ `AWSCodeStarFullAccess`
- ✅ `AmazonEC2FullAccess`
- ✅ `CloudWatchLogsFullAccess`

### Option B: Use Custom Policy (More Secure)

1. IAM Console → Users → `terraform-aws-user` → Add permissions → Create inline policy
2. Click **JSON** tab
3. Copy and paste the contents of [`iam/terraform-user-full-permissions.json`](file:///c:/games/java%20code/ete-cicd-aws/iam/terraform-user-full-permissions.json)
4. Click **Review policy**
5. Name: `CICD-Pipeline-Setup-Policy`
6. Click **Create policy**

---

## Step 2: Create CodeStar Connection (Manual - One Time)

This MUST be done via AWS Console (requires GitHub OAuth):

1. Go to: https://console.aws.amazon.com/codesuite/settings/connections
2. Click **"Create connection"**
3. Provider: **GitHub**
4. Connection name: `github-cicd-connection`
5. Click **"Connect to GitHub"**
6. Authorize AWS and select repository: `HimanshuNaik19/ete-cicd-aws`
7. **Copy the Connection ARN** (you'll need it)

---

## Step 3: Run Automated Setup Script

Now I can create everything via CLI! Run this PowerShell script:

```powershell
cd "c:\games\java code\ete-cicd-aws"

# Set your connection ARN (replace with your actual ARN from Step 2)
$CONNECTION_ARN = "arn:aws:codeconnections:us-east-1:323069970632:connection/YOUR_CONNECTION_ID"

# 1. Create S3 bucket
$BUCKET_NAME = "cicd-pipeline-artifacts-323069970632"
aws s3 mb s3://$BUCKET_NAME --region us-east-1
aws s3api put-bucket-versioning --bucket $BUCKET_NAME --versioning-configuration Status=Enabled
aws s3api put-bucket-encryption --bucket $BUCKET_NAME --server-side-encryption-configuration '{\"Rules\":[{\"ApplyServerSideEncryptionByDefault\":{\"SSEAlgorithm\":\"AES256\"}}]}'
aws s3api put-public-access-block --bucket $BUCKET_NAME --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# 2. Create IAM roles
powershell -ExecutionPolicy Bypass -File infrastructure\setup-iam-roles.ps1

# 3. Create CodeBuild project
aws codebuild create-project --cli-input-json file://aws-config/codebuild-project.json

# 4. Create CodeDeploy application
aws deploy create-application --application-name CICD-Demo-App --compute-platform Server

# 5. Create CodeDeploy deployment group
aws deploy create-deployment-group `
  --application-name CICD-Demo-App `
  --deployment-group-name Production-Fleet `
  --service-role-arn arn:aws:iam::323069970632:role/CodeDeploy-Service-Role `
  --deployment-config-name CodeDeployDefault.OneAtATime `
  --ec2-tag-filters Key=DeploymentGroup,Value=Production-Fleet,Type=KEY_AND_VALUE `
  --auto-rollback-configuration enabled=true,events=DEPLOYMENT_FAILURE

# 6. Launch EC2 instance
# Note: Replace KEY_NAME with your actual EC2 key pair name
$KEY_NAME = "aws-cicd-key"
$AMI_ID = "ami-0c55b159cbfafe1f0"  # Amazon Linux 2 in us-east-1

# Create security group
$SG_ID = aws ec2 create-security-group `
  --group-name cicd-app-sg `
  --description "Security group for CI/CD application" `
  --query 'GroupId' --output text

# Add security group rules
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 3000 --cidr 0.0.0.0/0

# Launch EC2 instance
$INSTANCE_ID = aws ec2 run-instances `
  --image-id $AMI_ID `
  --instance-type t2.micro `
  --key-name $KEY_NAME `
  --security-group-ids $SG_ID `
  --iam-instance-profile Name=EC2-CodeDeploy-Profile `
  --user-data file://infrastructure/user-data.sh `
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=CICD-App-Server},{Key=DeploymentGroup,Value=Production-Fleet}]' `
  --query 'Instances[0].InstanceId' --output text

Write-Host "EC2 Instance ID: $INSTANCE_ID"

# Wait for instance to be running
aws ec2 wait instance-running --instance-ids $INSTANCE_ID

# Get public IP
$PUBLIC_IP = aws ec2 describe-instances `
  --instance-ids $INSTANCE_ID `
  --query 'Reservations[0].Instances[0].PublicIpAddress' --output text

Write-Host "EC2 Public IP: $PUBLIC_IP"

# 7. Update pipeline configuration with your connection ARN
# (You'll need to manually update aws-config/codepipeline.json with your CONNECTION_ARN)

# 8. Create CodePipeline
aws codepipeline create-pipeline --cli-input-json file://aws-config/codepipeline.json

Write-Host "`n=== Setup Complete! ==="
Write-Host "S3 Bucket: $BUCKET_NAME"
Write-Host "EC2 Instance: $INSTANCE_ID"
Write-Host "Public IP: $PUBLIC_IP"
Write-Host "`nNext: Push code to GitHub to trigger the pipeline!"
```

---

## Step 4: Push Code to GitHub

```powershell
git init
git add .
git commit -m "Initial commit - AWS CI/CD Pipeline"
git remote add origin https://github.com/HimanshuNaik19/ete-cicd-aws.git
git branch -M main
git push -u origin main
```

---

## Step 5: Monitor Pipeline

1. Go to CodePipeline Console
2. Watch `CICD-Demo-Pipeline` execute all stages
3. Once complete, test your application:

```powershell
curl http://$PUBLIC_IP:3000
curl http://$PUBLIC_IP:3000/health
curl http://$PUBLIC_IP:3000/api/info
```

---

## Summary

With the right permissions, the entire setup is automated:
- ✅ S3 bucket creation
- ✅ IAM roles and instance profiles
- ✅ CodeBuild project
- ✅ CodeDeploy application and deployment group
- ✅ EC2 instance with proper tags and IAM profile
- ✅ CodePipeline configuration
- ✅ Automated deployment on every push

**Total setup time: ~10 minutes** (vs 2+ hours manually!)
