output "db_host" {
  description = "RDS hostname"
  value       = aws_db_instance.this.address
}

output "db_name" {
  description = "Database name"
  value       = var.db_name
}

output "db_port" {
  description = "Database port"
  value       = var.db_port
}

output "rds_master_secret_arn" {
  description = "ARN of the RDS master secret"
  value       = aws_db_instance.this.master_user_secret[0].secret_arn
}