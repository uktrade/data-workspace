variable "prefix" {
    type = string
    description = "Resource name prefix"
}

variable "glacier_transition_days" {
  type = number
  description =  "Number of days before moving logs to glacier"
  default = 180
}

variable "retention_days" {
  type = number
  description = "number of days to retain logs before deletion"
  default = 365
}

variable "log_retention_days" {
    type = number
    description = "number of days to retain logs from sagemaker"
    default = 180
}

