output "db_endpoint" {
  description = "RDS endpoint (hostname:port) for the database"
  value       = aws_db_instance.this.endpoint
}

output "db_port" {
  description = "Database port"
  value       = aws_db_instance.this.port
}

output "db_sg_id" {
  description = "Security group ID assigned to the RDS instance"
  value       = aws_security_group.db.id
}

output "db_admin_secret_arn" {
  description = "ARN of the Secrets Manager secret for DB admin password"
  value       = aws_secretsmanager_secret.db_admin_credentials.arn
}

output "db_app_secret_arn" {
  description = "ARN of the Secrets Manager secret for DB app password"
  value       = aws_secretsmanager_secret.db_app_credentials.arn
}