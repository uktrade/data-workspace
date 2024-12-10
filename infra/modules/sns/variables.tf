variable "prefix" {
    type = string
    description = "Prefix for SNS topic name"
}

variable "account_id" {
    type = string
    description = "account ID for the SNS topic"
}

variable "notification_email" {
    type = list(string)
    description = "Emails for SNS subscription"
}