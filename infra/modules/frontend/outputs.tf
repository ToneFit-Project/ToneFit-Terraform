output "acm_validation_cname" {
  description = "가비아 DNS에 등록할 CNAME 레코드 (인증서 검증용)"
  value = {
    for dvo in aws_acm_certificate.frontend.domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }
}

output "bucket_name" {
  description = "S3 버킷명 — GitHub Actions에서 빌드 파일 업로드 시 사용"
  value       = aws_s3_bucket.frontend.id
}

output "bucket_arn" {
  value = aws_s3_bucket.frontend.arn
}

output "cloudfront_domain" {
  description = "CloudFront 기본 도메인 — 도메인 연결 전 임시 접속 주소"
  value       = aws_cloudfront_distribution.frontend.domain_name
}

output "cloudfront_distribution_id" {
  description = "GitHub Actions에서 캐시 무효화 시 사용 (aws cloudfront create-invalidation)"
  value       = aws_cloudfront_distribution.frontend.id
}
