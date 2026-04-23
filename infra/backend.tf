terraform {
  backend "s3" {
    bucket = "tonefit-tfstate"
    key    = "prod/terraform.tfstate"
    region = "ap-northeast-2"
  }
}
