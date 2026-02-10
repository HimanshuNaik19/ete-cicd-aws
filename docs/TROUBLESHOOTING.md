# Troubleshooting Guide

This guide helps you diagnose and resolve common issues with the AWS CI/CD pipeline.

---

## Pipeline Issues

### Pipeline Not Triggering on Code Push

**Symptoms**:
- Code pushed to GitHub but pipeline doesn't start
- Pipeline shows no recent executions

**Possible Causes & Solutions**:

1. **GitHub Connection Not Authorized**
   ```bash
   # Check connection status
   aws codestar-connections get-connection --connection-arn <arn>
   ```
   - Status should be "AVAILABLE"
   - If "PENDING", complete authorization in AWS Console

2. **Wrong Branch Configured**
   - Verify pipeline is watching the correct branch
   - Check `aws-config/codepipeline.json` → `BranchName`

3. **CodePipeline Service Role Missing Permissions**
   ```bash
   # Verify role has UseConnection permission
   aws iam get-role-policy \
     --role-name CodePipeline-Service-Role \
     --policy-name CodePipeline-Policy
   ```

---

## Build Stage Issues

### Build Fails During Install Phase

**Symptoms**:
- Build fails with "command not found" or dependency errors
- CloudWatch Logs show installation failures

**Solutions**:

1. **Check buildspec.yml Syntax**
   ```yaml
   # Verify runtime version matches
   install:
     runtime-versions:
       nodejs: 14  # Must be available in build image
   ```

2. **Verify Build Image**
   - Ensure `aws/codebuild/standard:5.0` supports Node.js 14
   - Check [AWS CodeBuild images documentation](https://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref-available.html)

3. **Check package.json**
   ```bash
   # Locally verify dependencies install
   cd sample-app
   npm install
   ```

### Build Fails During Test Phase

**Symptoms**:
- Tests fail in CodeBuild but pass locally
- Test timeout errors

**Solutions**:

1. **Check Test Output in CloudWatch Logs**
   ```bash
   # View build logs
   aws codebuild batch-get-builds --ids <build-id>
   ```

2. **Verify Test Configuration**
   ```json
   // package.json
   "scripts": {
     "test": "jest --coverage"
   }
   ```

3. **Increase Build Timeout**
   - Edit `aws-config/codebuild-project.json`
   - Increase `timeoutInMinutes` value

### Build Artifacts Not Created

**Symptoms**:
- Build succeeds but deploy stage fails
- "Artifact not found" errors

**Solutions**:

1. **Verify Artifact Configuration in buildspec.yml**
   ```yaml
   artifacts:
     files:
       - '**/*'
     base-directory: sample-app
   ```

2. **Check S3 Bucket Permissions**
   ```bash
   # Verify CodeBuild can write to S3
   aws s3 ls s3://YOUR_BUCKET_NAME/
   ```

3. **Review Build Logs**
   - Check post_build phase completed successfully
   - Verify files exist in base-directory

---

## Deploy Stage Issues

### CodeDeploy Agent Not Running

**Symptoms**:
- Deployment fails immediately
- Error: "The deployment failed because no instances were found"

**Solutions**:

1. **SSH into EC2 and Check Agent Status**
   ```bash
   ssh -i ~/.ssh/YOUR_KEY.pem ec2-user@INSTANCE_IP
   sudo service codedeploy-agent status
   ```

2. **Start CodeDeploy Agent**
   ```bash
   sudo service codedeploy-agent start
   sudo chkconfig codedeploy-agent on
   ```

3. **Reinstall CodeDeploy Agent**
   ```bash
   cd /home/ec2-user
   wget https://aws-codedeploy-us-east-1.s3.us-east-1.amazonaws.com/latest/install
   chmod +x ./install
   sudo ./install auto
   ```

4. **Check Agent Logs**
   ```bash
   tail -f /var/log/aws/codedeploy-agent/codedeploy-agent.log
   ```

### Deployment Fails - No Instances Found

**Symptoms**:
- Error: "The deployment failed because no instances were found for your deployment group"

**Solutions**:

1. **Verify EC2 Instance Tags**
   ```bash
   aws ec2 describe-instances \
     --instance-ids <instance-id> \
     --query 'Reservations[0].Instances[0].Tags'
   ```
   - Must have tag: `DeploymentGroup=Production-Fleet`

2. **Check Deployment Group Configuration**
   ```bash
   aws deploy get-deployment-group \
     --application-name CICD-Demo-App \
     --deployment-group-name Production-Fleet
   ```

3. **Verify Instance is Running**
   ```bash
   aws ec2 describe-instance-status --instance-ids <instance-id>
   ```

### Deployment Fails During ApplicationStop

**Symptoms**:
- Deployment fails at ApplicationStop lifecycle event
- Script errors in CodeDeploy logs

**Solutions**:

1. **Check Script Permissions**
   ```bash
   # Scripts must be executable
   chmod +x scripts/*.sh
   git add scripts/
   git commit -m "Fix script permissions"
   git push
   ```

2. **Review stop_server.sh Script**
   ```bash
   # Manually test the script
   ssh -i ~/.ssh/YOUR_KEY.pem ec2-user@INSTANCE_IP
   cd /home/ec2-user/app
   bash scripts/stop_server.sh
   ```

3. **Check Deployment Logs**
   ```bash
   # On EC2 instance
   cat /opt/codedeploy-agent/deployment-root/deployment-logs/codedeploy-agent-deployments.log
   ```

### Deployment Fails During BeforeInstall

**Symptoms**:
- Deployment fails installing dependencies
- Node.js or npm not found

**Solutions**:

1. **Verify Node.js Installation**
   ```bash
   ssh -i ~/.ssh/YOUR_KEY.pem ec2-user@INSTANCE_IP
   node --version
   npm --version
   ```

2. **Check install_dependencies.sh Script**
   ```bash
   # Run script manually
   sudo bash scripts/install_dependencies.sh
   ```

3. **Review Script Logs**
   - Check `/var/log/aws/codedeploy-agent/` for errors

### Deployment Fails During ValidateService

**Symptoms**:
- Application deployed but validation fails
- Health check returns non-200 status

**Solutions**:

1. **Check Application Logs**
   ```bash
   ssh -i ~/.ssh/YOUR_KEY.pem ec2-user@INSTANCE_IP
   cat /home/ec2-user/app/app.log
   ```

2. **Verify Application is Running**
   ```bash
   ps aux | grep node
   curl http://localhost:3000/health
   ```

3. **Check Port Availability**
   ```bash
   netstat -tuln | grep 3000
   ```

4. **Test Health Endpoint**
   ```bash
   # Should return 200
   curl -v http://localhost:3000/health
   ```

---

## IAM Permission Issues

### Access Denied Errors

**Symptoms**:
- "Access Denied" or "UnauthorizedOperation" errors
- Pipeline stages fail with permission errors

**Solutions**:

1. **Verify Role Trust Relationships**
   ```bash
   aws iam get-role --role-name CodePipeline-Service-Role
   ```

2. **Check Policy Attachments**
   ```bash
   aws iam list-role-policies --role-name CodePipeline-Service-Role
   aws iam get-role-policy \
     --role-name CodePipeline-Service-Role \
     --policy-name CodePipeline-Policy
   ```

3. **Verify S3 Bucket ARN in Policies**
   - Ensure bucket ARN matches actual bucket name
   - Check both bucket and object permissions

4. **Check EC2 Instance Profile**
   ```bash
   aws ec2 describe-instances \
     --instance-ids <instance-id> \
     --query 'Reservations[0].Instances[0].IamInstanceProfile'
   ```

---

## Application Issues

### Application Not Responding

**Symptoms**:
- Cannot access application via browser
- Connection timeout or refused

**Solutions**:

1. **Verify Security Group Rules**
   ```bash
   aws ec2 describe-security-groups --group-ids <sg-id>
   ```
   - Ensure port 3000 is open to 0.0.0.0/0 (or your IP)

2. **Check Application Process**
   ```bash
   ssh -i ~/.ssh/YOUR_KEY.pem ec2-user@INSTANCE_IP
   ps aux | grep node
   ```

3. **Restart Application**
   ```bash
   cd /home/ec2-user/app
   bash scripts/stop_server.sh
   bash scripts/start_server.sh
   ```

4. **Check Application Logs**
   ```bash
   tail -f /home/ec2-user/app/app.log
   ```

### Application Crashes After Deployment

**Symptoms**:
- Application starts but crashes immediately
- Process not found after deployment

**Solutions**:

1. **Check for Missing Dependencies**
   ```bash
   cd /home/ec2-user/app
   npm install
   ```

2. **Verify Environment Variables**
   ```bash
   # Check start_server.sh sets required variables
   cat scripts/start_server.sh
   ```

3. **Test Application Manually**
   ```bash
   cd /home/ec2-user/app
   NODE_ENV=production PORT=3000 node app.js
   ```

4. **Check for Port Conflicts**
   ```bash
   lsof -i :3000
   ```

---

## S3 Bucket Issues

### Artifacts Not Stored

**Symptoms**:
- Build completes but artifacts missing from S3
- Deploy stage cannot find artifacts

**Solutions**:

1. **Verify Bucket Exists**
   ```bash
   aws s3 ls s3://YOUR_BUCKET_NAME/
   ```

2. **Check Bucket Permissions**
   ```bash
   aws s3api get-bucket-policy --bucket YOUR_BUCKET_NAME
   ```

3. **Verify CodeBuild Has Write Access**
   - Check `iam/codebuild-policy.json`
   - Ensure S3 PutObject permission exists

---

## Rollback Issues

### Automatic Rollback Not Working

**Symptoms**:
- Deployment fails but doesn't rollback
- Previous version not restored

**Solutions**:

1. **Verify Rollback Configuration**
   ```bash
   aws deploy get-deployment-group \
     --application-name CICD-Demo-App \
     --deployment-group-name Production-Fleet \
     --query 'deploymentGroupInfo.autoRollbackConfiguration'
   ```

2. **Enable Auto-Rollback**
   ```bash
   aws deploy update-deployment-group \
     --application-name CICD-Demo-App \
     --current-deployment-group-name Production-Fleet \
     --auto-rollback-configuration enabled=true,events=DEPLOYMENT_FAILURE
   ```

3. **Manual Rollback**
   ```bash
   # Get previous deployment ID
   aws deploy list-deployments \
     --application-name CICD-Demo-App \
     --deployment-group-name Production-Fleet
   
   # Create rollback deployment
   aws deploy create-deployment \
     --application-name CICD-Demo-App \
     --deployment-group-name Production-Fleet \
     --update-outdated-instances-only
   ```

---

## Debugging Tips

### Enable Verbose Logging

1. **CodeBuild**
   - Add `set -x` to buildspec.yml commands
   - Check CloudWatch Logs

2. **CodeDeploy**
   - Add `set -x` to deployment scripts
   - Check `/var/log/aws/codedeploy-agent/`

3. **Application**
   - Set `NODE_ENV=development` for detailed errors
   - Add console.log statements

### Useful AWS CLI Commands

```bash
# Get pipeline execution details
aws codepipeline get-pipeline-execution \
  --pipeline-name CICD-Demo-Pipeline \
  --pipeline-execution-id <execution-id>

# Get build details
aws codebuild batch-get-builds --ids <build-id>

# Get deployment details
aws deploy get-deployment --deployment-id <deployment-id>

# List recent deployments
aws deploy list-deployments \
  --application-name CICD-Demo-App \
  --max-items 10

# Check EC2 instance status
aws ec2 describe-instance-status --instance-ids <instance-id>
```

---

## Getting Help

### AWS Support Resources
- [AWS CodePipeline Documentation](https://docs.aws.amazon.com/codepipeline/)
- [AWS CodeBuild Documentation](https://docs.aws.amazon.com/codebuild/)
- [AWS CodeDeploy Documentation](https://docs.aws.amazon.com/codedeploy/)
- [AWS Forums](https://forums.aws.amazon.com/)
- [AWS Support Center](https://console.aws.amazon.com/support/)

### Community Resources
- Stack Overflow (tag: aws-codepipeline, aws-codebuild, aws-codedeploy)
- AWS Reddit: r/aws
- GitHub Issues for this project

### Logging Best Practices
- Always check CloudWatch Logs first
- Enable detailed logging during troubleshooting
- Save error messages and stack traces
- Document solutions for future reference
