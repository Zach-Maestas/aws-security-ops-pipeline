output "db_app_credentials_secret_arn" {
  description = "ARN of the Secrets Manager secret for DB app password"
  value       = aws_secretsmanager_secret.db_app_credentials.arn
}