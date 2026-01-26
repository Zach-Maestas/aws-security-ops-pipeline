/*
--------------------------------------------------------------
Modules for Network, ACM, Application, Data (RDS), and Secrets
--------------------------------------------------------------
*/

module "network" {
  source               = "./modules/network"
  project              = var.project
  vpc_cidr             = var.vpc_cidr
  azs                  = var.azs
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_app_subnet_cidrs = var.private_app_subnet_cidrs
  private_db_subnet_cidrs  = var.private_db_subnet_cidrs
}

# ACM Certificate
module "acm" {
  source         = "./modules/acm"
  project        = var.project
  domain_name    = var.domain_name
  hosted_zone_id = var.route53_zone_id    
  alb_dns_name = module.app.alb_dns_name
}

# Application Module
module "app" {
  source             = "./modules/app"
  project            = var.project
  vpc_id             = module.network.vpc_id
  public_subnet_ids  = module.network.public_subnet_ids
  private_subnet_ids = module.network.private_app_subnet_ids
  certificate_arn    = module.acm.certificate_arn
  secret_name        = var.secret_name
}

# Data Module (RDS)
module "data" {
  source                = "./modules/data"
  project               = var.project
  vpc_id                = module.network.vpc_id
  private_db_subnet_ids = module.network.private_db_subnet_ids
  app_sg_id             = module.app.ec2_sg_id
}

# Secrets Module
module "secrets" {
  source        = "./modules/secrets"
  secret_name   = var.secret_name
  ec2_role_arn  = module.app.ec2_role_arn
  vpc_id        = module.network.vpc_id
}

# Internet Gateway
resource "aws_internet_gateway" "this" {
  vpc_id = module.network.vpc_id
  tags   = { Name = "${var.project}-igw" }
}

/*
--------------------------------------------------------------
Resources for Routing and NAT
--------------------------------------------------------------
*/

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




