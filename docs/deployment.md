# Deployment Guide

This guide explains how to deploy, verify, and tear down the **Secure AWS Architecture Capstone** using Terraform.  
It’s written for clarity and reproducibility, and demonstrates professional IaC documentation standards.

---

## ⚙️ Prerequisites

Before deploying, confirm your local environment and AWS account are properly configured.

### Required Tools
Install:
- Terraform v1.6 or newer  
- AWS CLI v2  
- Git  

After installation, confirm each tool is working (you’ll verify versions manually).

### AWS Account Permissions
Use an IAM user or role with permissions to manage:
- VPC  
- EC2  
- IAM  
- S3  
- Route 53  
- ACM  
- RDS (if deploying the database)

Recommended managed policies:
- AmazonVPCFullAccess
- AmazonEC2FullAccess
- IAMFullAccess
- AmazonRoute53FullAccess
- AWSCertificateManagerFullAccess
- AmazonS3FullAccess
- AmazonRDSFullAccess

### Configure AWS CLI
Run `aws configure`, then verify with `aws sts get-caller-identity`.

---

## 📁 Project Structure

All Terraform files live in `/infrastructure`, organized by module for modularity and clarity.

Each module defines a major layer:
- **network/** – VPC, subnets, gateways, routing, endpoints  
- **app/** – ALB, EC2, Auto Scaling, security groups  
- **data/** – RDS and Secrets Manager integration  
- **acm/** – Certificate creation and DNS validation
- **secrets/** – Secrets management  

---

## 🚀 Deployment Steps

### 1. Clone the Repository
Clone the repo and navigate into the infrastructure directory.
`git clone https://github.com/Zach-Maestas/secure-aws-architecture-capstone.git`
`cd secure-aws-architecture-capstone/infrastructure`

### 2. Initialize Terraform
Initialize the working directory, install providers, and set up the backend.
`terraform init`
You should see confirmation that Terraform initialized successfully.

### 3. Validate the Configuration
Validate all Terraform files to ensure there are no syntax or reference errors.
`terraform validate`
A “Success! The configuration is valid.” message confirms correctness.

### 4. Review the Execution Plan
Generate a plan to preview the infrastructure Terraform will create or modify.
`terraform plan -out=tfplan`
Inspect the plan output to confirm resources and dependencies before proceeding.

### 5. Apply the Infrastructure
Apply the saved plan to provision the AWS environment.
`terraform apply "tfplan"`

Confirm when prompted. Terraform will begin creating resources including:
- VPC and subnets across two Availability Zones  
- Internet and NAT Gateways  
- Route tables and VPC endpoints  
- ACM certificate with DNS validation  
- Application Load Balancer with HTTPS  
- (Optional) EC2 instances and RDS  

Deployment typically takes 10–15 minutes.

---

## 🔍 Verification

Once deployment completes, note the output values:
- ALB DNS name  
- S3 website endpoint (if used)  
- RDS endpoint (if provisioned)

Verify:
1. Navigate to the ALB DNS name in a browser using HTTPS.  
2. Confirm a valid SSL certificate and secure connection.  
3. Check AWS Console for:
   - VPC structure (public, private-app, and private-db subnets)
   - Route tables correctly associated
   - ACM certificate status “Issued”
   - ALB listeners on ports 80 and 443
   - RDS not publicly accessible

---

## 🧹 Teardown

To safely destroy resources when finished testing:
`terraform destroy`
If you receive errors about `prevent_destroy` protections, update your variables or module settings to temporarily disable them, or use targeted destroys such as:
`terraform destroy -target=aws_s3_bucket.frontend`


---

## ⚠️ Notes & Tips

- Keep Terraform state remote in S3 with a DynamoDB lock for production use.  
- Never commit `.tfstate` files or secrets to GitHub.  
- ACM DNS validation can take a few minutes; rerun `terraform apply` if needed.  
- Destroy stacks when not in use to minimize AWS costs.  

---

## 🧩 Next Phase

This project serves as **Capstone 1** in a three-part Cloud Security Engineering portfolio.  
The next phase, the **[CloudOps Capstone](https://github.com/Zach-Maestas/cloudops-capstone)**, builds upon this foundation with CI/CD, monitoring, scaling, and automated security operations.

---



