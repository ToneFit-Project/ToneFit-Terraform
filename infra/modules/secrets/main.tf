locals {
  name_prefix = "${var.project}-${var.environment}"
}

# DB 접속 정보 — Terraform이 RDS 생성 후 자동 주입
resource "aws_secretsmanager_secret" "db" {
  name        = "${var.project}/db"
  description = "ToneFit RDS PostgreSQL connection info"

  tags = merge(var.tags, { Name = "${local.name_prefix}-secret-db" })
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id

  secret_string = jsonencode({
    host     = var.db_host
    port     = tostring(var.db_port)
    dbname   = var.db_name
    username = var.db_username
    password = var.db_password
  })
}

# 앱 시크릿 — 생성만 하고 값은 AWS 콘솔에서 수동 입력
# 입력 항목: GEMINI_API_KEY, JWT_SECRET, GOOGLE_CLIENT_ID, GOOGLE_CLIENT_SECRET
resource "aws_secretsmanager_secret" "app" {
  name        = "${var.project}/app"
  description = "ToneFit application secrets (manual entry required)"

  tags = merge(var.tags, { Name = "${local.name_prefix}-secret-app" })
}
