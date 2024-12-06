variable "budget_name" {
    type   = string
    description     = "AWS Budget name"
}

variable "budget_limit" {
    type    = string
    default = null
    description     = "Optional monthly budget limit for AWS for the budget"
}

variable "time_unit" {
    description = "Budget time unit, i.e. Monthly, etc"
    type = string
    default = "MONTHLY"
}

variable "notification_thresholds" {
    type = list(number)
    default = [80, 100]
    description = "list of notification thresholds in %"
}

# variable "notification_email" {
#     type = string
#     description = "email for who recieves budget alerts - likely not going to work "
# }

variable "sns_topic_arn" {
    type = string
    description = "ARN of SNS topic for budget alerts"
  
}

variable "cost_filter_service" {
    type = string
    description = "service to apply cost filter on"
    default = "Amazon SageMaker"
}
