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


variable "alarms" {
  type = list(object({
    alarm_name_prefix   = string
    alarm_description   = string
    metric_name         = string
    namespace           = string
    comparison_operator = string
    threshold           = number
    evaluation_periods  = number
    datapoints_to_alarm = number
    period              = number
    statistic           = string
    slack_webhook_url   = string
    alarm_actions       = list(string)
    ok_actions          = list(string)
  }))
  description = "List of CloudWatch alarms to be created"
}


variable "alarm_composites" {
  type = list(object({
    alarm_name        = string
    alarm_description = string
    alarm_rule        = string
    alarm_actions     = list(string)
    ok_actions        = list(string)
    slack_webhook_url = string
    emails            = list(string)
  }))
  description = "List of CloudWatch composite alarms to be created utilizing pre-existing alarms"
}


variable "aws_account_id" {
  type = string
}
