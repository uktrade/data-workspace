variable "endpoint_name" {
  type        = string
  description = "Name of the SageMaker endpoint"
}

variable "endpoint_config_name" {
  type        = string
  description = "Name of the SageMaker endpoint configuration"
}

variable "variant_name" {
  type        = string
  description = "Name of the SageMaker endpoint production variant"
}

variable "model_name" {
  type        = string
  description = "Name of the SageMaker model to be deployed to the endpoint"
}

variable "instance_type" {
  type        = string
  description = "Instance type for the endpoint"
}

variable "initial_instance_count" {
  type        = number
  description = "Initial instance count for the endpoint"
}

variable "container_startup_health_check_timeout_in_seconds" {
  type        = number
  default     = 90
  description = "Health check timeout in seconds"
}

variable "async_output_s3_path" {
  type        = string
  description = "S3 path for async output"
}
