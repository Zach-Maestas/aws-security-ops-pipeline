# DB Subnet Group
resource "aws_db_subnet_group" "this" {
  name       = "${var.project}-db-subnet-group"
  subnet_ids = var.private_db_subnet_ids
  tags = { Name = "${var.project}-db-subnet-group" }
}

# Database Security Group
resource "aws_security_group" "db" {
  name        = "${var.project}-db-sg"
  description = "Allow DB access from App Layer"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = local.db_creds.port
    to_port         = local.db_creds.port
    protocol        = "tcp"
    security_groups = [var.app_sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project}-db-sg" }
}

# RDS Instance
resource "aws_db_instance" "this" {
  identifier              = lower("${var.project}-rds")
  db_name                 = local.db_creds.db_name
  engine                  = local.db_creds.engine
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  max_allocated_storage   = 100
  storage_type            = "gp3"
  storage_encrypted       = true
  username                = local.db_creds.username
  password                = local.db_creds.password
  port                    = local.db_creds.port
  db_subnet_group_name    = aws_db_subnet_group.this.name
  vpc_security_group_ids  = [aws_security_group.db.id]
  multi_az                = true
  publicly_accessible     = false
  backup_retention_period = 7
  deletion_protection     = true
  skip_final_snapshot     = true
  
  lifecycle {
    prevent_destroy = true
    ignore_changes  = [username, password]
  }

  tags = { Name = "${var.project}-rds" }
}

# Retrieve DB credentials from Secrets Manager
data "aws_secretsmanager_secret_version" "db" {
  secret_id = "capstone/secureaws/db-credentials"
}

# Decode the secret string
locals {
  db_creds = jsondecode(data.aws_secretsmanager_secret_version.db.secret_string)
}