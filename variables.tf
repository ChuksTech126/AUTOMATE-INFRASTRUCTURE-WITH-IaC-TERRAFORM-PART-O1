variable "region" {
  type        = string
  description = "region of the provider"
  default     = "us-east-1"
}

variable "cidr_block" {
  type    = string
  default = "172.16.0.0/16"
}

variable "enable_dns_support" {
  type    = bool
  default = true
}

variable "enable_dns_hostnames" {
  type    = bool
  default = true
}

variable "preferred_number_of_subnets" {
  type    = number
  default = 2
}

variable "block_public_acls" {
  type    = bool
  default = true
}

variable "block_public_policy" {
  type    = bool
  default = true
}

variable "ignore_public_acls" {
  type    = bool
  default = true
}

variable "restrict_public_buckets" {
  type    = bool
  default = true
}

variable "aws_internet_gateway" {
  type    = string
  default = "chuks_gateway"
}

variable "aws_route_table" {
  type    = string
  default = "chuks_route_table"
}

