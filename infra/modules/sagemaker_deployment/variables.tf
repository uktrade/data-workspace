variable "sns_success_topic_arn" {
  type        = string
  description = "ARN of the SNS topic for Sagemaker successful async outputs"
}


variable "model_name" {
  type        = string
  description = "Name of the SageMaker model"
}


variable "s3_output_path" {
  type        = string
  description = "Where the async output of the model is sent"
}


variable "execution_role_arn" {
  type        = string
  description = "Execution role ARN for SageMaker"
}


variable "container_image" {
  type        = string
  description = "Container image for the model"
}


variable "model_uri" {
  type        = string
  description = "S3 URL where the model data is located"
}


variable "model_uri_compression" {
  type        = string
  description = "Whether the model weights are stored compressed and if so what compression type"
}


variable "environment_variables" {
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


variable "instance_type" {
  type        = string
  description = "Instance type for the endpoint"
}


variable "max_capacity" {
  type        = number
  description = "Maximum capacity for autoscaling"
}


variable "min_capacity" {
  type        = number
  description = "Minimum capacity for autoscaling"
}


variable "scale_up_cooldown" {
  type        = number
  description = "Cooldown period for scale up"
}


variable "scale_down_cooldown" {
  type        = number
  description = "Cooldown period for scale down"
}

variable "backlog_threshold_high" {
  type        = number
  description = "Threshold for high backlog alarm"
}


variable "backlog_threshold_low" {
  type        = number
  description = "Threshold for low backlog alarm"
}


variable "cpu_threshold_high" {
  type        = number
  description = "Threshold for high CPU alarm (NOTE this varies based on number of vCPU)"
}


variable "cpu_threshold_low" {
  type        = number
  description = "Threshold for low CPU alarm (NOTE this varies based on number of vCPU)"
}


variable "gpu_threshold_high" {
  type        = number
  description = "Threshold for high GPU alarm (NOTE this varies based on number of GPU)"
}


variable "gpu_threshold_low" {
  type        = number
  description = "Threshold for low GPU alarm (NOTE this varies based on number of GPU)"
}


variable "ram_threshold_high" {
  type        = number
  description = "Threshold for high RAM alarm"
}


variable "ram_threshold_low" {
  type        = number
  description = "Threshold for low RAM alarm"
}


variable "harddisk_threshold_high" {
  type        = number
  description = "Threshold for high HardDisk alarm"
}


variable "harddisk_threshold_low" {
  type        = number
  description = "Threshold for low HardDisk alarm"
}


variable "evaluation_periods_high" {
  type        = number
  description = "Number of evaluation periods to consider for high alarm states"
}


variable "datapoints_to_alarm_high" {
  type        = number
  description = "Number of datapoints within an evaluation period to require for low alarm states"
}


variable "evaluation_periods_low" {
  type        = number
  description = "Number of evaluation periods to consider for low alarm states"
}


variable "datapoints_to_alarm_low" {
  type        = number
  description = "Number of datapoints within an evaluation period to require for low alarm states"
}


variable "aws_account_id" {
  type = string
}
