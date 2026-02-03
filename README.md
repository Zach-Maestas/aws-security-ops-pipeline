# AWS DevSecOps Security Operations Project

A production-patterned AWS infrastructure project demonstrating cloud security engineering: secure networking, least-privilege IAM, secrets management, containerized deployment, and reproducible infrastructure-as-code — built to be deployed, torn down, and redeployed from a single command.

## Architecture

<!-- TODO: Add architecture diagram (draw.io, Lucidchart, or Mermaid) -->

### Components
| Layer | Service | Purpose |
|-------|---------|---------|
| Networking | VPC, Public/Private Subnets, NAT Gateway | Network isolation — compute and data in private subnets |
| Compute | ECS Fargate | Serverless container orchestration, no EC2 management |
| Load Balancing | ALB + ACM | HTTPS termination with valid TLS certificate |
| Data | RDS PostgreSQL | Managed relational database in private subnet |
| Secrets | AWS Secrets Manager | Runtime credential injection, no plaintext secrets |
| Registry | ECR | Private container image storage |
| Observability | CloudWatch Logs | Centralized container and application logging |

## Security Controls

| Control | Implementation | Evidence |
|---------|---------------|----------|
| Network isolation | ECS tasks and RDS in private subnets, ALB in public | Security group rules in Terraform |
| Least-privilege IAM | Scoped task role and execution role | IAM policy snippets |
| Secrets management | DB credentials via Secrets Manager, injected at runtime | Task definition config |
| TLS/HTTPS | ALB listener with ACM certificate | ALB listener configuration |
| No broad ingress | Security groups scoped to specific ports and sources | SG rule audit |
| Non-root container | Application runs as non-root user | Dockerfile `USER` directive |

## Quick Start

### Prerequisites
- AWS CLI configured with appropriate credentials
- Terraform >= 1.0
- Docker with buildx support
- GNU Make

### Deploy
```bash
make deploy
```
This runs: `terraform apply` → `build & push images` → `DB init` → `scale up ECS service`

### Verify
```bash
curl https://api.zachmaestas-capstone.com/health
curl https://api.zachmaestas-capstone.com/ready
```

### Destroy
```bash
make destroy
```

## Project Phases

### Phase 0: Clean Baseline Deploy — ✅ Complete
Reproducible Terraform deployment producing a working HTTPS endpoint: ALB → ECS Fargate → RDS, with Secrets Manager integration. I utilized a "bootstrap" method with Bash scripting to allow for teardown of entire infrastructure without having to manually re-initialize the RDS instance each time (done through ECS db_init task). Also, I refocused the project on security controls, and removed components not serving a security objective like the S3 frontend.

### Phase 1: CI/CD Pipeline with OIDC — 🔲 Planned
GitHub Actions CI running on PRs and merges with OIDC-based AWS authentication — no long-lived access keys. Includes formatting, linting, unit tests, least-privilege CI roles, and versioned image builds.

### Phase 2: Cloud Security — logging, detection, monitoring and incident response — 🔲 Planned
CloudTrail, GuardDuty, and Security Hub integration with a documented triage workflow. Includes automated incident response via EventBridge/Lambda with a written incident narrative.

### Phase 3: DevSecOps Pipeline Gates — 🔲 Planned
Security scanning in CI: dependency/supply chain scanning, container image scanning, IaC security analysis (tfsec/checkov), and secret detection with enforced pass/fail gates.

### Phase 4: Environment Separation — 🔲 Planned
Multi-environment deployment (dev/staging/prod) with environment-specific configurations, promotion workflows, and isolated state management.

## Evidence

Evidence artifacts for completed phases are in [`docs/evidence/`](docs/evidence/).

<!-- Link to specific evidence as phases complete -->

## Known Limitations

- Single environment (dev) — no staging/prod separation yet
- ECR repository names and ECS cluster names are hardcoded in deployment scripts
- No CI/CD pipeline yet (Phase 1)
- No automated security scanning or alerting (Phases 2-3)
- Cost-optimized for portfolio use — designed for full teardown/rebuild, not persistent uptime

## Tech Stack

| Tool | Version | Purpose |
|------|---------|---------|
| Terraform | >= 1.0 | Infrastructure as Code |
| AWS ECS Fargate | - | Container orchestration |
| Flask + Gunicorn | Python 3.x | API application |
| PostgreSQL | 15 | Relational database (RDS) |
| Docker | buildx | Container builds |

## Documentation

- [Deployment Guide](docs/deployment.md) — detailed deploy, verify, teardown, and troubleshooting steps
- [Security Design](docs/security.md) — in-depth security controls, IAM design, and trade-off rationale

## Repository Structure

```
.
├── application/
│   └── backend/          # Flask API (Dockerfile, app.py, Gunicorn)
├── infrastructure/
│   ├── scripts/
│   │   ├── db_init/      # DB initialization container
│   │   └── deploy/             # Build, init, and scale scripts
│   └── terraform/
│       └── modules/      # network, app, data, secrets, acm
├── Makefile              # Deploy/destroy orchestration
└── README.md             # Project roadmap and standards
```
