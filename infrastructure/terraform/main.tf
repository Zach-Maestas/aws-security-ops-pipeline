/*
==============================================================================
Root Configuration: DevSecOps Security Operations Platform
==============================================================================
Orchestrates all infrastructure modules for a secure, multi-tier web application:
- Network: VPC, subnets, routing, NAT gateways
- Secrets: Application database credentials
- Data: RDS PostgreSQL database
- ACM: TLS certificate for HTTPS
- App: ALB, ECS Fargate, ECR, S3 frontend hosting

This configuration deploys a production-ready architecture with:
- Encrypted data at rest and in transit
- Least-privilege IAM and security groups
- Private subnet placement for sensitive resources
- Automated certificate management
==============================================================================
*/

# Network Module
module "network" {
  source                   = "./modules/network"
  project                  = var.project
  vpc_cidr                 = var.vpc_cidr
  azs                      = var.azs
  public_subnet_cidrs      = var.public_subnet_cidrs
  private_app_subnet_cidrs = var.private_app_subnet_cidrs
  private_db_subnet_cidrs  = var.private_db_subnet_cidrs
}

# Secrets Module
module "secrets" {
  source  = "./modules/secrets"
  project = var.project
}

# Data Module (RDS)
module "data" {
  source                = "./modules/data"
  project               = var.project
  vpc_id                = module.network.vpc_id
  private_db_subnet_ids = module.network.private_db_subnet_ids
  rds_sg_id             = module.network.rds_sg_id
}

# ACM Certificate
module "acm" {
  source         = "./modules/acm"
  project        = var.project
  domain_name    = var.domain_name
  hosted_zone_id = var.route53_zone_id
}

# Application Module
module "app" {
  source                 = "./modules/app"
  project                = var.project
  vpc_id                 = module.network.vpc_id
  public_subnet_ids      = module.network.public_subnet_ids
  private_app_subnet_ids = module.network.private_app_subnet_ids
  private_db_subnet_ids  = module.network.private_db_subnet_ids
  alb_sg_id              = module.network.alb_sg_id
  ecs_tasks_sg_id        = module.network.ecs_tasks_sg_id
  certificate_arn        = module.acm.certificate_arn
  db_app_credentials_arn = module.secrets.db_app_credentials_secret_arn
  db_host                = module.data.db_host
  db_name                = module.data.db_name
  db_port                = module.data.db_port
  rds_master_secret_arn  = module.data.rds_master_secret_arn
}

/*
==============================================================================
Internet Connectivity: IGW, NAT, and VPC Endpoints
==============================================================================
*/

# Internet Gateway
resource "aws_internet_gateway" "this" {
  vpc_id = module.network.vpc_id
  tags   = { Name = "${var.project}-igw" }
}

# Elastic IPs for NAT Gateways
resource "aws_eip" "nat" {
  count  = length(module.network.public_subnet_ids)
  domain = "vpc"
}

# NAT Gateway
resource "aws_nat_gateway" "this" {
  count         = length(module.network.public_subnet_ids)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = module.network.public_subnet_ids[count.index]
  tags = {
    Name = "${var.project}-nat-${count.index + 1}"
  }
}

# Route for public subnets → IGW
resource "aws_route" "public_internet_access" {
  route_table_id         = module.network.public_rt_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

# Route for private subnets → NAT
resource "aws_route" "private_internet_access" {
  count                  = length(module.network.private_rt_ids)
  route_table_id         = module.network.private_rt_ids[count.index]
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[count.index].id
}

# S3 VPC Endpoint
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = module.network.vpc_id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = module.network.private_rt_ids # Attach to all private route tables across AZs

  tags = {
    Name = "${var.project}-s3-endpoint"
  }
}

/*
==============================================================================
DNS: Route 53 Record for ALB
==============================================================================
*/

# Create Route 53 A record for the API pointing to the ALB
resource "aws_route53_record" "api_record" {
  zone_id = var.route53_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = module.app.alb_dns_name
    zone_id                = module.app.alb_zone_id
    evaluate_target_health = true
  }
}
