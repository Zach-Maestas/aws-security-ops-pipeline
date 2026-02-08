# Security Design

This document details the security controls implemented in the AWS DevSecOps Security Operations project. For a summary, see the [README Security Controls Table](../README.md#security-controls).

---

## Network Security

### VPC Segmentation

The network uses a three-tier subnet architecture across two Availability Zones:

| Tier | Subnets | Contains | Internet Access |
|------|---------|----------|----------------|
| Public | `public-1`, `public-2` | ALB, NAT Gateways | Direct (IGW) |
| Private App | `private-app-1`, `private-app-2` | ECS Fargate tasks | Outbound only (NAT) |
| Private Data | `private-db-1`, `private-db-2` | RDS PostgreSQL | None |

### Security Groups

Security groups enforce layer-to-layer traffic flow:

```
Internet → [ALB SG: 443 inbound] → [ECS SG: app port from ALB SG only] → [RDS SG: 5432 from ECS SG only]
```

| Security Group | Inbound | Outbound |
|---------------|---------|----------|
| ALB | 443 from `0.0.0.0/0` | App port to ECS SG |
| ECS Tasks | App port from ALB SG | 5432 to RDS SG, 443 to internet (NAT) |
| RDS | 5432 from ECS SG | None required |

No security group allows `0.0.0.0/0` on any port other than the ALB's HTTPS listener.

### Routing

- **Internet Gateway** — attached to public subnets only.
- **NAT Gateway** — provides outbound internet for private app subnets (image pulls, API calls).
- **Private data subnets** — no route to the internet in either direction.

---

## Identity & Access Management

### ECS Task Roles

Two separate IAM roles with distinct responsibilities:

| Role | Purpose | Permissions |
|------|---------|-------------|
| Execution Role | ECS agent pulls images and injects secrets | ECR read, Secrets Manager read |
| Task Role | Application runtime identity | Scoped to only what the app needs |

### Least Privilege Approach

- No `*` resource wildcards on sensitive actions.
- Execution role can only read specific secrets, not all secrets in the account.
- Task role is scoped to application needs — not reused across services.

---

## Secrets Management

### How Credentials Flow

```
Secrets Manager → ECS Task Definition (valueFrom) → Container environment variable → Application
```

- DB credentials are stored in AWS Secrets Manager, not in Terraform variables, environment files, or code.
- The ECS task definition references secrets by ARN using `valueFrom` — credentials are injected at container startup.
- The execution role has permission to read only the specific secret ARNs needed.
- No secret values appear in Terraform state as plaintext resource attributes.

---

## Transport Security

- **ALB Listener** — HTTPS (443) with ACM-issued TLS certificate.
- **HTTP redirect** — port 80 redirects to 443.
- **ACM validation** — DNS validation via Route 53 (automated in Terraform).

---

## Container Security

- **Non-root user** — the Dockerfile sets a non-root `USER` for the application process.
- **Minimal base image** — Python slim variant, reducing attack surface.
- **No SSH** — Fargate tasks have no SSH daemon; debugging through logs (CloudWatch planned for Phase 2).
- **Immutable deployments** — new code requires a new image push and service update.

---

## What This Architecture Does NOT Include (Yet)

These are planned for future phases and documented here for transparency:

| Gap | Planned Phase | Notes |
|-----|--------------|-------|
| CloudWatch logging | Phase 2 | No container log configuration yet |
| CloudTrail audit logging | Phase 2 | No API-level audit trail |
| GuardDuty threat detection | Phase 2 | No automated threat detection |
| Security Hub posture | Phase 2 | No centralized findings dashboard |
| Container image scanning | Phase 3 | No vulnerability scanning on images |
| IaC scanning (tfsec/checkov) | Phase 3 | No static analysis on Terraform |
| Secret detection in code | Phase 3 | No pre-commit or CI secret scanning |
| Encryption at rest (RDS/KMS) | Future | RDS uses default encryption, not CMK |
| WAF on ALB | Future | No web application firewall layer |
| VPC Flow Logs | Future | No network traffic logging |

---

## Security Trade-offs

<!-- TODO(human): Write 3-5 trade-offs you consciously made in this project. For each one: what did you choose, what's the risk, and why is it acceptable for a portfolio project? Example format:

**[Trade-off title]**
Chose X over Y because Z. The risk is [risk]. Acceptable here because [reason], but in production I would [what you'd change].
-->
