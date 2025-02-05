variable "vpc_id" {
  type        = string
  description = "VPC ID where SG will be created"
}

variable "prefix" {
  type        = string
  description = "Prefix for naming the SGs"
}

variable "cidr_blocks" {
  type        = any
  description = "List of CIDR blocks for SG rules"
}