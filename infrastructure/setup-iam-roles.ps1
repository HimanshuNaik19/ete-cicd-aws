# Setup IAM Roles Script for Windows PowerShell
# This script creates all required IAM roles for the CI/CD pipeline

Write-Host "=== Creating IAM Roles for CI/CD Pipeline ===" -ForegroundColor Cyan
Write-Host ""

# 1. Create CodePipeline Role
Write-Host "1. Creating CodePipeline Service Role..." -ForegroundColor Yellow
try {
    aws iam create-role `
        --role-name CodePipeline-Service-Role `
        --assume-role-policy-document file://iam/codepipeline-trust-policy.json `
        2>$null
}
catch {
    Write-Host "  Role already exists, skipping..." -ForegroundColor Gray
}

aws iam put-role-policy `
    --role-name CodePipeline-Service-Role `
    --policy-name CodePipeline-Policy `
    --policy-document file://iam/codepipeline-policy.json

Write-Host "  CodePipeline role created" -ForegroundColor Green
Write-Host ""

# 2. Create CodeBuild Role
Write-Host "2. Creating CodeBuild Service Role..." -ForegroundColor Yellow
try {
    aws iam create-role `
        --role-name CodeBuild-Service-Role `
        --assume-role-policy-document file://iam/codebuild-trust-policy.json `
        2>$null
}
catch {
    Write-Host "  Role already exists, skipping..." -ForegroundColor Gray
}

aws iam put-role-policy `
    --role-name CodeBuild-Service-Role `
    --policy-name CodeBuild-Policy `
    --policy-document file://iam/codebuild-policy.json

Write-Host "  CodeBuild role created" -ForegroundColor Green
Write-Host ""

# 3. Create CodeDeploy Role
Write-Host "3. Creating CodeDeploy Service Role..." -ForegroundColor Yellow
try {
    aws iam create-role `
        --role-name CodeDeploy-Service-Role `
        --assume-role-policy-document file://iam/codedeploy-trust-policy.json `
        2>$null
}
catch {
    Write-Host "  Role already exists, skipping..." -ForegroundColor Gray
}

aws iam put-role-policy `
    --role-name CodeDeploy-Service-Role `
    --policy-name CodeDeploy-Policy `
    --policy-document file://iam/codedeploy-policy.json

Write-Host "  CodeDeploy role created" -ForegroundColor Green
Write-Host ""

# 4. Create EC2 Instance Role and Profile
Write-Host "4. Creating EC2 Instance Role and Profile..." -ForegroundColor Yellow
try {
    aws iam create-role `
        --role-name EC2-CodeDeploy-Role `
        --assume-role-policy-document file://iam/ec2-trust-policy.json `
        2>$null
}
catch {
    Write-Host "  Role already exists, skipping..." -ForegroundColor Gray
}

aws iam put-role-policy `
    --role-name EC2-CodeDeploy-Role `
    --policy-name EC2-Instance-Policy `
    --policy-document file://iam/ec2-instance-policy.json

# Create instance profile
try {
    aws iam create-instance-profile `
        --instance-profile-name EC2-CodeDeploy-Profile `
        2>$null
}
catch {
    Write-Host "  Instance profile already exists, skipping..." -ForegroundColor Gray
}

# Add role to instance profile
try {
    aws iam add-role-to-instance-profile `
        --instance-profile-name EC2-CodeDeploy-Profile `
        --role-name EC2-CodeDeploy-Role `
        2>$null
}
catch {
    Write-Host "  Role already in profile, skipping..." -ForegroundColor Gray
}

Write-Host "  EC2 role and instance profile created" -ForegroundColor Green
Write-Host ""

Write-Host "=== IAM Roles Setup Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Created roles:" -ForegroundColor White
Write-Host "  - CodePipeline-Service-Role" -ForegroundColor Gray
Write-Host "  - CodeBuild-Service-Role" -ForegroundColor Gray
Write-Host "  - CodeDeploy-Service-Role" -ForegroundColor Gray
Write-Host "  - EC2-CodeDeploy-Role (with EC2-CodeDeploy-Profile)" -ForegroundColor Gray
Write-Host ""
Write-Host "Waiting 10 seconds for IAM roles to propagate..." -ForegroundColor Yellow
Start-Sleep -Seconds 10
Write-Host "Ready to proceed with next steps" -ForegroundColor Green
