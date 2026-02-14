# Manual Deployment Guide

## Quick Manual Deployment to Test Application

Since the automated deployment is having issues, let's manually deploy to verify the application works:

```bash
# SSH into EC2
cd ~\Downloads
ssh -i "aws-cicd-key.pem" ec2-user@100.31.154.155

# Install Node.js (if not already installed)
curl -sL https://rpm.nodesource.com/setup_14.x | sudo bash -
sudo yum install -y nodejs

# Clone and deploy
cd ~
git clone https://github.com/HimanshuNaik19/ete-cicd-aws.git app
cd app/sample-app

# Install dependencies and start
npm install --production
nohup node app.js > app.log 2>&1 &

# Check if running
ps aux | grep node
curl http://localhost:3000
```

## Test from your machine
```powershell
curl http://100.31.154.155:3000
curl http://100.31.154.155:3000/health
```

## Current Status

**✅ Working:**
- S3 bucket created
- All IAM roles created
- CodeBuild project - tests pass!
- CodeDeploy application created
- EC2 instance running
- CodePipeline created
- Source and Build stages complete successfully

**❌ Issue:**
- Deploy stage fails - scripts not executing
- Likely cause: appspec.yml line endings or format issue

## Next Steps

1. Test manual deployment (above)
2. Fix appspec.yml line endings
3. Simplify deployment scripts
4. Retry automated deployment
