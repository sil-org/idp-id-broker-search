variable "app_env" {
  type = string
}

variable "app_name" {
  default = "idp-id-broker-search"
}

variable "aws_region" {
  default = "us-east-1"
}

variable "aws_region_secondary" {
  default = "us-west-2"
}

variable "aws_region_new_primary" {
  default = "us-east-2"
}

variable "aws_access_key" {
  default = null
}

variable "aws_secret_key" {
  default = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
