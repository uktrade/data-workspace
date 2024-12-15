variable "sns_success_topic_arn" {
  type        = string
  description = "ARN of the SNS topic for Sagemaker successful async outputs"
}

variable "model_name" {
  type        = string
  description = "Name of the SageMaker model"
}

variable "execution_role_arn" {
  type        = string
  description = "Execution role ARN for SageMaker"
}

variable "container_image" {
  type        = string
  description = "Container image for the model"
}

variable "model_data_url" {
  type        = string
  description = "S3 URL where the model data is located"
}

variable "environment" {
  type        = map(string)
  description = "Environment variables for the container"
}

variable "security_group_ids" {
  type        = list(string)
  description = "List of security group IDs for the SageMaker model"
}

variable "subnets" {
  type        = list(string)
  description = "List of subnets for the SageMaker model"
}

variable "endpoint_config_name" {
  type        = string
  description = "Name of the endpoint configuration"
}

variable "endpoint_name" {
  type        = string
  description = "Name of the SageMaker endpoint"
}

variable "variant_name" {
  type        = string
  description = "Name of the production variant"
  default     = null
}

variable "instance_type" {
  type        = string
  description = "Instance type for the endpoint"
}

variable "initial_instance_count" {
  type        = number
  description = "Initial instance count for the endpoint"
}

variable "s3_output_path" {
  type        = string
  description = "S3 output path for async inference"
}

variable "max_capacity" {
  type        = number
  description = "Maximum capacity for autoscaling"
}

variable "min_capacity" {
  type        = number
  description = "Minimum capacity for autoscaling"
}

variable "scale_up_adjustment" {
  type        = number
  description = "Number of instances to scale up by"
}

variable "scale_up_cooldown" {
  type        = number
  description = "Cooldown period for scale up"
}

variable "scale_in_to_zero_cooldown" {
  type        = number
  description = "Cooldown period for scale down"
}


variable "alarms" {
  type = list(object({
    alarm_name          = string
    alarm_description   = string
    metric_name         = string
    namespace           = string
    comparison_operator = string
    threshold           = number
    evaluation_periods  = number
    datapoints_to_alarm = number
    period              = number
    statistic           = string
    alarm_actions       = optional(list(string), null)
  }))
  description = "List of CloudWatch alarms to be created"
}

variable "log_group_name" {
  type        = string
  description = "log group name, i.e. gpt-neo-125m..."
  default     = ""
}