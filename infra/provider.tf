terraform {
  required_version = ">= 1.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  # AWS_PROFILE 환경변수로 SSO 프로필 지정: export AWS_PROFILE=tonefit-infra
}

# CloudFront용 ACM 인증서는 반드시 us-east-1에 있어야 함
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}
