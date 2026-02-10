# Quick Setup Guide - Manual AWS Console Approach

Due to IAM permission constraints with the `terraform-aws-user`, you'll need to create the AWS resources via the AWS Console. This is actually a common approach and quite straightforward.

## Prerequisites
✅ CodeStar Connection created: `b698b20e-78ee-44ce-83c6-12944250f949`  
✅ GitHub repository configured: `HimanshuNaik19/ete-cicd-aws`  
✅ AWS Account ID: `323069970632`

---

## Step 1: Create IAM Roles (AWS Console)

### 1.1 CodePipeline Service Role

1. Go to **IAM Console** → **Roles** → **Create role**
2. **Trusted entity**: AWS service → **CodePipeline**
3. **Role name**: `CodePipeline-Service-Role`
4. **Permissions**: Attach these policies:
   - Create custom policy using [`iam/codepipeline-policy.json`](file:///c:/games/java%20code/ete-cicd-aws/iam/codepipeline-policy.json)
   - Or attach AWS managed policy: `AWSCodePipelineFullAccess` (easier)

### 1.2 CodeBuild Service Role

1. **IAM Console** → **Roles** → **Create role**
2. **Trusted entity**: AWS service → **CodeBuild**
3. **Role name**: `CodeBuild-Service-Role`
4. **Permissions**: Attach custom policy using [`iam/codebuild-policy.json`](file:///c:/games/java%20code/ete-cicd-aws/iam/codebuild-policy.json)

### 1.3 CodeDeploy Service Role

1. **IAM Console** → **Roles** → **Create role**
2. **Trusted entity**: AWS service → **CodeDeploy**
3. **Role name**: `CodeDeploy-Service-Role`
4. **Permissions**: Attach AWS managed policy: `AWSCodeDeployRole`

### 1.4 EC2 Instance Role

1. **IAM Console** → **Roles** → **Create role**
2. **Trusted entity**: AWS service → **EC2**
3. **Role name**: `EC2-CodeDeploy-Role`
4. **Permissions**: Attach custom policy using [`iam/ec2-instance-policy.json`](file:///c:/games/java%20code/ete-cicd-aws/iam/ec2-instance-policy.json)

---

## Step 2: Create S3 Bucket (AWS Console)

1. Go to **S3 Console** → **Create bucket**
2. **Bucket name**: `cicd-pipeline-artifacts-323069970632` (must be globally unique)
3. **Region**: `us-east-1`
4. **Settings**:
   - ✅ Block all public access
   - ✅ Enable versioning
   - ✅ Enable server-side encryption (SSE-S3)
5. Click **Create bucket**
6. **Save the bucket name** - you'll need it later

---

## Step 3: Update Configuration Files

Once you have the S3 bucket name, update these files:

### Update `aws-config/codebuild-project.json`
Replace `ARTIFACT_BUCKET` on line 30 with your bucket name:
```json
"location": "cicd-pipeline-artifacts-323069970632/build-cache"
```

### Update `aws-config/codepipeline.json`
Replace `ARTIFACT_BUCKET_NAME` on line 6 with your bucket name:
```json
"location": "cicd-pipeline-artifacts-323069970632"
```

---

## Step 4: Create CodeBuild Project (AWS Console)

1. Go to **CodeBuild Console** → **Create project**
2. **Project name**: `cicd-demo-build-project`
3. **Source**: 
   - Provider: **AWS CodePipeline**
4. **Environment**:
   - Image: **Managed image**
   - Operating system: **Ubuntu**
   - Runtime: **Standard**
   - Image: **aws/codebuild/standard:5.0**
   - Service role: **Existing** → Select `CodeBuild-Service-Role`
5. **Buildspec**: Use buildspec file → `buildspec.yml`
6. **Artifacts**:
   - Type: **AWS CodePipeline**
7. **Logs**:
   - CloudWatch logs: **Enabled**
   - Group name: `/aws/codebuild/cicd-demo`
8. Click **Create build project**

---

## Step 5: Launch EC2 Instance (AWS Console)

1. Go to **EC2 Console** → **Launch Instance**
2. **Name**: `CICD-App-Server`
3. **AMI**: Amazon Linux 2 (free tier eligible)
4. **Instance type**: `t2.micro`
5. **Key pair**: Select or create a key pair
6. **Network settings**:
   - Create security group with:
     - SSH (22) - Your IP
     - HTTP (80) - Anywhere
     - Custom TCP (3000) - Anywhere
7. **Advanced details**:
   - IAM instance profile: `EC2-CodeDeploy-Role`
   - User data: Copy content from [`infrastructure/user-data.sh`](file:///c:/games/java%20code/ete-cicd-aws/infrastructure/user-data.sh)
8. **Tags**: Add tag `DeploymentGroup` = `Production-Fleet`
9. Click **Launch instance**
10. **Save the Instance ID and Public IP**

---

## Step 6: Create CodeDeploy Application (AWS Console)

1. Go to **CodeDeploy Console** → **Create application**
2. **Application name**: `CICD-Demo-App`
3. **Compute platform**: **EC2/On-premises**
4. Click **Create application**

### Create Deployment Group

1. Click **Create deployment group**
2. **Deployment group name**: `Production-Fleet`
3. **Service role**: Select `CodeDeploy-Service-Role`
4. **Deployment type**: **In-place**
5. **Environment configuration**:
   - **Amazon EC2 instances**
   - Tag: Key=`DeploymentGroup`, Value=`Production-Fleet`
6. **Deployment settings**: `CodeDeployDefault.OneAtATime`
7. **Load balancer**: Uncheck (not using)
8. Click **Create deployment group**

---

## Step 7: Create CodePipeline (AWS Console)

1. Go to **CodePipeline Console** → **Create pipeline**
2. **Pipeline name**: `CICD-Demo-Pipeline`
3. **Service role**: Select `CodePipeline-Service-Role`
4. **Artifact store**: Custom → Select your S3 bucket
5. Click **Next**

### Source Stage
1. **Source provider**: **GitHub (Version 2)**
2. **Connection**: Select your connection `github-cicd-connection`
3. **Repository**: `HimanshuNaik19/ete-cicd-aws`
4. **Branch**: `main`
5. Click **Next**

### Build Stage
1. **Build provider**: **AWS CodeBuild**
2. **Project name**: `cicd-demo-build-project`
3. Click **Next**

### Deploy Stage
1. **Deploy provider**: **AWS CodeDeploy**
2. **Application name**: `CICD-Demo-App`
3. **Deployment group**: `Production-Fleet`
4. Click **Next**

5. **Review** and click **Create pipeline**

---

## Step 8: Push Code to GitHub

```powershell
# Initialize git (if not already done)
git init
git add .
git commit -m "Initial commit - AWS CI/CD Pipeline"

# Add remote
git remote add origin https://github.com/HimanshuNaik19/ete-cicd-aws.git
git branch -M main
git push -u origin main
```

The pipeline should automatically trigger!

---

## Step 9: Monitor Pipeline

1. Go to **CodePipeline Console**
2. Click on `CICD-Demo-Pipeline`
3. Watch the stages execute:
   - ✅ Source (pulls from GitHub)
   - ✅ Build (runs tests)
   - ✅ Deploy (deploys to EC2)

---

## Step 10: Test the Application

```powershell
# Get your EC2 instance public IP from the console
# Then test:
curl http://YOUR_EC2_IP:3000
curl http://YOUR_EC2_IP:3000/health
curl http://YOUR_EC2_IP:3000/api/info
```

---

## Troubleshooting

If you encounter issues, check:
- **CodeBuild logs**: CloudWatch Logs → `/aws/codebuild/cicd-demo`
- **CodeDeploy logs**: SSH into EC2 → `tail -f /var/log/aws/codedeploy-agent/codedeploy-agent.log`
- **Application logs**: SSH into EC2 → `cat /home/ec2-user/app/app.log`

See full troubleshooting guide: [`docs/TROUBLESHOOTING.md`](file:///c:/games/java%20code/ete-cicd-aws/docs/TROUBLESHOOTING.md)

---

## Summary

This manual approach is actually very common in enterprise environments where developers don't have full IAM permissions. The AWS Console provides a user-friendly way to create all resources with proper validation.

Once everything is set up, your pipeline will be fully automated - every push to GitHub will trigger the full CI/CD workflow!
