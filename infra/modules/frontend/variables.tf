variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "domain_name" {
  type    = string
  default = ""
  description = "커스텀 도메인 (비어있으면 CloudFront 기본 도메인 사용)"
}

variable "ec2_domain" {
  type        = string
  description = "EC2 백엔드 퍼블릭 DNS (CloudFront API 오리진)"
}

variable "tags" {
  type    = map(string)
  default = {}
}
