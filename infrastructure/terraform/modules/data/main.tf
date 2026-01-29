# DB Subnet Group
resource "aws_db_subnet_group" "this" {
  name       = "${var.project}-db-subnet-group"
  subnet_ids = var.private_db_subnet_ids
  tags       = { Name = "${var.project}-db-subnet-group" }
}

# Generate Random Administrator Password
resource "random_password" "db_admin_password" {
  length = 32
  special = true
}

# Generate Random App Password
resource "random_password" "db_app_password" {
  length = 32
  special = true
}

# Create Secrets Manager Secret for DB Admin Credentials
resource "aws_secretsmanager_secret" "db_admin_credentials" {
  name = "${var.project}/db-admin"
}

# Create Secrets Manager Secret for DB App Credentials
resource "aws_secretsmanager_secret" "db_app_credentials" {
  name = "${var.project}/db-app"
}

# Store DB Admin Password in Secrets Manager
resource "aws_secretsmanager_secret_version" "db_admin_credentials_version" {
  secret_id     = aws_secretsmanager_secret.db_admin_credentials.id
  secret_string = jsonencode(
  {
    username = var.db_admin_username
    password = random_password.db_admin_password.result
  })
}

# Store DB App Password in Secrets Manager
resource "aws_secretsmanager_secret_version" "db_app_credentials_version" {
  secret_id     = aws_secretsmanager_secret.db_app_credentials.id
  secret_string = jsonencode(
  {
    username = var.db_app_username
    password = random_password.db_app_password.result
  })
}

# Database Security Group
resource "aws_security_group" "db" {
  name        = "${var.project}-db-sg"
  description = "Allow DB access from App Layer"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = var.db_port
    to_port         = var.db_port
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
  db_name                 = var.db_name
  engine                  = "postgres"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  max_allocated_storage   = 100
  storage_type            = "gp3"
  storage_encrypted       = true
  username                = var.db_admin_username
  password                = random_password.db_admin_password.result
  port                    = var.db_port
  db_subnet_group_name    = aws_db_subnet_group.this.name
  vpc_security_group_ids  = [aws_security_group.db.id]
  multi_az                = true
  publicly_accessible     = false
  backup_retention_period = 7
  skip_final_snapshot     = true

  tags = { Name = "${var.project}-rds" }
}

