locals {
  name_prefix    = "${var.project}-${var.environment}"
  log_group_base = "/${var.project}/${var.environment}"
}

# ── SNS (알람 수신) ────────────────────────────────────────────

resource "aws_sns_topic" "alerts" {
  name = "${local.name_prefix}-alerts"
  tags = var.tags
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.alarm_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

# ── CloudWatch Log Groups (보존 7일) ───────────────────────────

resource "aws_cloudwatch_log_group" "nginx_access" {
  name              = "${local.log_group_base}/nginx/access"
  retention_in_days = 7
  tags              = var.tags
}

resource "aws_cloudwatch_log_group" "nginx_error" {
  name              = "${local.log_group_base}/nginx/error"
  retention_in_days = 7
  tags              = var.tags
}

resource "aws_cloudwatch_log_group" "app" {
  name              = "${local.log_group_base}/app"
  retention_in_days = 7
  tags              = var.tags
}

# ── CloudWatch Alarms (4개) ────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${local.name_prefix}-cpu-high"
  alarm_description   = "CPU 사용률 80% 초과 (2회 연속)"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = var.instance_id
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "memory_high" {
  alarm_name          = "${local.name_prefix}-memory-high"
  alarm_description   = "메모리 사용률 80% 초과 (CWAgent 커스텀 메트릭)"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = var.instance_id
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "disk_high" {
  alarm_name          = "${local.name_prefix}-disk-high"
  alarm_description   = "디스크 사용률 80% 초과 (CWAgent 커스텀 메트릭)"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "disk_used_percent"
  namespace           = "CWAgent"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  # AL2023 + t3.small 기본 루트 디바이스 기준
  dimensions = {
    InstanceId = var.instance_id
    path       = "/"
    device     = "xvda1"
    fstype     = "xfs"
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "status_check_failed" {
  alarm_name          = "${local.name_prefix}-status-check-failed"
  alarm_description   = "EC2 상태 확인 실패"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = var.instance_id
  }

  tags = var.tags
}

# ── CloudWatch Dashboard ───────────────────────────────────────

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = local.name_prefix

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 8
        height = 6
        properties = {
          title   = "CPU 사용률 (%)"
          view    = "timeSeries"
          metrics = [["AWS/EC2", "CPUUtilization", "InstanceId", var.instance_id]]
          period  = 300
          stat    = "Average"
          region  = "ap-northeast-2"
          yAxis   = { left = { min = 0, max = 100 } }
          annotations = { horizontal = [{ value = 80, color = "#ff0000", label = "임계값 80%" }] }
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 0
        width  = 8
        height = 6
        properties = {
          title   = "메모리 사용률 (%)"
          view    = "timeSeries"
          metrics = [["CWAgent", "mem_used_percent", "InstanceId", var.instance_id]]
          period  = 300
          stat    = "Average"
          region  = "ap-northeast-2"
          yAxis   = { left = { min = 0, max = 100 } }
          annotations = { horizontal = [{ value = 80, color = "#ff0000", label = "임계값 80%" }] }
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 0
        width  = 8
        height = 6
        properties = {
          title   = "디스크 사용률 (%)"
          view    = "timeSeries"
          metrics = [["CWAgent", "disk_used_percent", "InstanceId", var.instance_id, "path", "/", "device", "xvda1", "fstype", "xfs"]]
          period  = 300
          stat    = "Average"
          region  = "ap-northeast-2"
          yAxis   = { left = { min = 0, max = 100 } }
          annotations = { horizontal = [{ value = 80, color = "#ff0000", label = "임계값 80%" }] }
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title   = "네트워크 I/O (bytes)"
          view    = "timeSeries"
          metrics = [
            ["AWS/EC2", "NetworkIn", "InstanceId", var.instance_id, { label = "수신" }],
            ["AWS/EC2", "NetworkOut", "InstanceId", var.instance_id, { label = "송신" }]
          ]
          period = 300
          stat   = "Sum"
          region = "ap-northeast-2"
        }
      },
      {
        type   = "alarm"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "알람 상태"
          alarms = [
            aws_cloudwatch_metric_alarm.cpu_high.arn,
            aws_cloudwatch_metric_alarm.memory_high.arn,
            aws_cloudwatch_metric_alarm.disk_high.arn,
            aws_cloudwatch_metric_alarm.status_check_failed.arn,
          ]
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 12
        width  = 24
        height = 6
        properties = {
          title  = "Nginx 에러 로그"
          query  = "SOURCE '${local.log_group_base}/nginx/error' | fields @timestamp, @message | sort @timestamp desc | limit 50"
          region = "ap-northeast-2"
          view   = "table"
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 18
        width  = 24
        height = 6
        properties = {
          title  = "앱 오류 로그 (ERROR)"
          query  = "SOURCE '${local.log_group_base}/app' | fields @timestamp, @message | filter @message like /ERROR/ | sort @timestamp desc | limit 50"
          region = "ap-northeast-2"
          view   = "table"
        }
      }
    ]
  })
}
