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

variable "tags" {
  type    = map(string)
  default = {}
}
