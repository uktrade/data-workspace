variable "create" {
  default = true
  description = "bool Whether to create the SNS topic"
}

variable "sns_topic_name" {
  type        = string
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the SNS topic"
  default     = {}
}

variable "lambda_arn" {
  type        = string
  description = "ARN of the Lambda function to subscribe to the topic"
}

variable "enable_notifications" {
  type        = bool
  description = "Enable or disable notifications for this topic"
  default     = true
}

variable "lambda_name" {
  type        = string
  description = "Name of the Lambda function"
}
