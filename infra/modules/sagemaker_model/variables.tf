variable "model_name" {
  type        = string
  description = "Name of the SageMaker model"
}

variable "execution_role_arn" {
  type        = string
  description = "The ARN of the execution role for SageMaker"
}

variable "container_image" {
  type        = string
  description = "The URI of the container image for the SageMaker model"
}

variable "model_data_url" {
  type        = string
  description = "The S3 URL of the model data"
}

variable "environment" {
  type        = map(string)
  description = "The environment variables for the model container"
}

variable "security_group_ids" {
  type        = list(string)
  description = "List of security group IDs for the VPC configuration"
}

variable "subnets" {
  type        = list(string)
  description = "List of subnet IDs for the VPC configuration"
}
