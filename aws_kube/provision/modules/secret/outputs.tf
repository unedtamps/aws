output "secret_name" {
  value = aws_secretsmanager_secret.app.name
}

output "secret_arn" {
  value = aws_secretsmanager_secret.app.arn
}

output "external_secrets_role_arn" {
  description = "IAM role ARN used by External Secrets Operator."
  value       = aws_iam_role.external_secrets.arn
}
