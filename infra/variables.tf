variable "project" {
  type    = string
  default = "tonefit"
}

variable "environment" {
  type    = string
  default = "prod"
}

variable "aws_region" {
  type    = string
  default = "ap-northeast-2"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "ec2_instance_type" {
  type    = string
  default = "t3.small"
}

variable "ec2_key_pair_name" {
  type = string
}

variable "allowed_ssh_cidrs" {
  type = list(string)
}

variable "rds_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "rds_engine_version" {
  type    = string
  default = "16"
}

variable "rds_db_name" {
  type    = string
  default = "tonefit"
}

variable "rds_username" {
  type = string
}

variable "rds_password" {
  type      = string
  sensitive = true
}

variable "rds_allocated_storage" {
  type    = number
  default = 20
}

variable "domain_name" {
  type    = string
  default = ""
}

variable "api_subdomain" {
  type    = string
  default = ""
}

variable "tags" {
  type = map(string)
  default = {
    Project   = "tonefit"
    ManagedBy = "terraform"
  }
}
