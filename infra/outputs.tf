output "ec2_public_ip" {
  description = "EC2 Elastic IP — GitHub Actions EC2_HOST Secret에 입력"
  value       = module.ec2.public_ip
}

output "rds_endpoint" {
  description = "RDS 엔드포인트 — Secrets Manager tonefit/db에 자동 저장됨"
  value       = module.rds.endpoint
}

output "db_secret_arn" {
  description = "Secrets Manager ARN (tonefit/db)"
  value       = module.secrets.db_secret_arn
}

output "app_secret_arn" {
  description = "Secrets Manager ARN (tonefit/app) — GEMINI_API_KEY 등 수동 입력 필요"
  value       = module.secrets.app_secret_arn
}

output "frontend_bucket" {
  description = "S3 버킷명 — 프론트엔드 빌드 파일 업로드 대상"
  value       = module.frontend.bucket_name
}

output "cloudfront_domain" {
  description = "CloudFront 접속 도메인 — 도메인 연결 전 임시 주소"
  value       = module.frontend.cloudfront_domain
}

output "cloudfront_distribution_id" {
  description = "CloudFront Distribution ID — 배포 후 캐시 무효화에 사용"
  value       = module.frontend.cloudfront_distribution_id
}
