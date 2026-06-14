variable "instance_id" {
  description = "EC2 인스턴스 ID (SSM SendCommand 대상)"
  type        = string
}

variable "cloudfront_distribution_id" {
  description = "CloudFront 배포 ID (캐시 무효화 대상)"
  type        = string
}
