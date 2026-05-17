variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "instance_id" {
  type = string
}

variable "alarm_email" {
  type    = string
  default = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}
