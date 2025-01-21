variable "budget_name" {
  type        = string
  description = "AWS Budget name"
}

variable "budget_limit" {
  type        = string
  default     = null
  description = "Optional monthly budget limit for AWS for the budget"
}

variable "notification_email" {
  type        = list(string)
  description = "email for who recieves budget alerts"
}

variable "sns_topic_arn" {
  type        = string
  description = "ARN of SNS topic for budget alerts"

}

variable "cost_filter_service" {
  type        = string
  description = "service to apply cost filter on"
  default     = "Amazon SageMaker"
}
