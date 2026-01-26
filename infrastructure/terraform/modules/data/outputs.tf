output "db_endpoint" {
  description = "RDS endpoint (hostname:port) for the database"
  value       = aws_db_instance.this.endpoint
  sensitive   = true
}

output "db_port" {
  description = "Database port"
  value       = aws_db_instance.this.port
  sensitive   = true
}

output "db_sg_id" {
  description = "Security group ID assigned to the RDS instance"
  value       = aws_security_group.db.id
}
