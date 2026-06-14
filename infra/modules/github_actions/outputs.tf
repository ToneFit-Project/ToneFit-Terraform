output "role_arn" {
  description = "GitHub Actions에서 assume 할 IAM Role ARN"
  value       = aws_iam_role.github_deploy.arn
}
