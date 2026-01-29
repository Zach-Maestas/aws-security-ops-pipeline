# Generate Random App Password
resource "random_password" "db_app_password" {
  length  = 32
  special = true
}

# Create Secrets Manager Secret for DB App Credentials
resource "aws_secretsmanager_secret" "db_app_credentials" {
  name = "${var.project}/db-app"
}

# Store DB App Password in Secrets Manager
resource "aws_secretsmanager_secret_version" "db_app_credentials_version" {
  secret_id = aws_secretsmanager_secret.db_app_credentials.id
  secret_string = jsonencode(
    {
      username = "app_items_rw"
      password = random_password.db_app_password.result
  })
}