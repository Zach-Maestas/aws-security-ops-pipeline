# DB Subnet Group
resource "aws_db_subnet_group" "this" {
  name       = "${var.project}-db-subnet-group"
  subnet_ids = var.private_db_subnet_ids
  tags       = { Name = "${var.project}-db-subnet-group" }
}

# RDS Instance
resource "aws_db_instance" "this" {
  identifier                  = lower("${var.project}-rds")
  db_name                     = var.db_name
  engine                      = "postgres"
  instance_class              = "db.t3.micro"
  allocated_storage           = 20
  max_allocated_storage       = 100
  storage_type                = "gp3"
  storage_encrypted           = true
  username                    = var.db_admin_username
  manage_master_user_password = true
  port                        = var.db_port
  db_subnet_group_name        = aws_db_subnet_group.this.name
  vpc_security_group_ids      = [var.rds_sg_id]
  multi_az                    = true
  publicly_accessible         = false
  backup_retention_period     = 7
  skip_final_snapshot         = true

  tags = { Name = "${var.project}-rds" }
}

