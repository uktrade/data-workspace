variable "domain_name" {
  type        = string
  description = "The Domain name of the service, i.e. SageMaker"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "subnet_ids" {
  type        = any
  description = "subnet ids"
}

variable "execution_role_arn" {
  type        = string
  description = "The execution role"
}
