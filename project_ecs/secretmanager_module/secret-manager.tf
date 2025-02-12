resource "aws_secretsmanager_secret" "rds_credentials" {
  name        = "rds_credentials"
  description = "RDS instance credentials"
}

resource "aws_secretsmanager_secret_version" "rds_credentials_user" {
  secret_id     = aws_secretsmanager_secret.rds_credentials.id
  secret_string = jsonencode({
    username = "admin123"
  })
}

resource "aws_secretsmanager_secret_version" "rds_credential_pass" {
  secret_id     = aws_secretsmanager_secret.rds_credentials.id
  secret_string = jsonencode({
    password = "admin123"
  })
}

output "secret_pass_arn" {
  value = aws_secretsmanager_secret_version.rds_credential_pass.arn
}

output "secret_user_arn" {
  value = aws_secretsmanager_secret_version.rds_credentials_user.arn
}