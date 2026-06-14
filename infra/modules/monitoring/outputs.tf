output "dashboard_url" {
  value = "https://ap-northeast-2.console.aws.amazon.com/cloudwatch/home?region=ap-northeast-2#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}

output "sns_topic_arn" {
  value = aws_sns_topic.alerts.arn
}

output "log_group_app" {
  value = aws_cloudwatch_log_group.app.name
}

output "log_group_nginx_access" {
  value = aws_cloudwatch_log_group.nginx_access.name
}

output "log_group_nginx_error" {
  value = aws_cloudwatch_log_group.nginx_error.name
}
