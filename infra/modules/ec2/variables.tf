variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_id" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.small"
}

variable "key_pair_name" {
  type = string
}

variable "allowed_ssh_cidrs" {
  type = list(string)
}

variable "db_host" {
  description = "RDS 엔드포인트 (systemd 환경변수 DB_HOST)"
  type        = string
}

variable "db_port" {
  description = "RDS 포트 (systemd 환경변수 DB_PORT)"
  type        = number
  default     = 5432
}

variable "tags" {
  type    = map(string)
  default = {}
}
