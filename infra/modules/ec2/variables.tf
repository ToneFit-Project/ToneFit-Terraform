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

variable "tags" {
  type    = map(string)
  default = {}
}
