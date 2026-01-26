output "secret_arn" {
  description = "ARN of the database secret"
  value       = data.aws_secretsmanager_secret.db.arn
}
