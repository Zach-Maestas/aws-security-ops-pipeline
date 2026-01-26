# Security Design

This document outlines the key security controls and design principles implemented in the **Secure AWS Architecture Capstone**.  
The infrastructure was built with defense-in-depth, least privilege, and AWS Well-Architected best practices in mind.

---

## 🧱 Network Security

### VPC Segmentation
The network follows a **three-tier architecture**:
- **Public Subnets** – contain only the Application Load Balancer (ALB) and NAT Gateways.  
  - ALB accepts HTTPS traffic only.  
  - NAT Gateways allow private subnets outbound internet access for updates.
- **Private App Subnets** – host EC2 instances or containers running the application backend.  
  - No direct internet access.  
  - Outbound-only via NAT Gateway.  
  - Inbound allowed **only** from ALB security group.
- **Private DB Subnets** – dedicated for Amazon RDS.  
  - No internet access.  
  - Accessible only from private app subnets through the database port (default 5432 for PostgreSQL).

### Routing & Gateways
- **Internet Gateway (IGW)** attached only to public subnets.  
- **NAT Gateways** used for outbound updates in private tiers.  
- **S3 Gateway Endpoint** allows private access to S3 without traversing the internet.  
- Route tables are explicitly defined and associated per subnet type.

---

## 🔒 Access Control

### IAM Roles & Policies
- **Principle of Least Privilege (PoLP)** enforced for all resources.  
- EC2 instances use **instance profiles** for access to limited AWS services (e.g., Secrets Manager, CloudWatch).  
- Separate IAM roles for Terraform state management vs runtime components.  
- Terraform runs under a **dedicated IAM user or assumed role** with fine-grained permissions.  
- Inline policies avoided; instead, **managed and reusable policies** are attached to roles.

### SSH & Management
- Direct SSH access to instances is **disabled by default**.  
- When necessary, access is done via **AWS Systems Manager Session Manager** for audited, temporary access.  
- No hardcoded credentials or key pairs stored in Terraform files.

---

## 🧩 Data Protection

### Encryption
- **At Rest:**  
  - S3 buckets have **default encryption (AES-256)** enabled.  
  - RDS storage encrypted using **AWS KMS-managed keys**.  
  - Secrets stored in **AWS Secrets Manager** are encrypted automatically with KMS.
- **In Transit:**  
  - HTTPS enforced via **AWS ACM-issued certificate** on the ALB.  
  - ALB redirects all HTTP traffic to HTTPS (port 443).  
  - Internal connections restricted to private VPC CIDR ranges.

### Secrets Management
- Database credentials and other sensitive values are stored in **AWS Secrets Manager**.  
- Secrets are referenced dynamically in Terraform rather than hardcoded in variables.  
- Application instances use IAM roles to retrieve secrets securely at runtime.

---

## 🛡️ Infrastructure Safeguards

### Security Groups
Each layer has its own security group:
- **ALB SG:** Allows inbound 80/443 from the internet, outbound to app SG.  
- **App SG:** Allows inbound from ALB SG only, outbound to DB SG.  
- **DB SG:** Allows inbound from app SG only, no public access.

### Network ACLs
- NACLs provide a second layer of subnet-level protection.  
- Default deny-all inbound for non-explicit traffic.  
- Outbound rules scoped to required CIDR ranges only.

### Lifecycle Protections
Critical resources (e.g., RDS, S3) include:
```hcl
lifecycle {
  prevent_destroy = true
}
```
This prevents accidental deletion of persistent data.

### 🔐 Summary

This architecture prioritizes:
- Layered defense through subnet isolation and strict routing.
- Identity-based access using IAM roles instead of static credentials.
- Encrypted storage and communication at all times.
- Logging and monitoring for continuous visibility and incident response.
These controls collectively deliver a secure, resilient, and auditable AWS environment suitable for production-grade workloads.
