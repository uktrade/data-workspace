variable "prefix" {
    type = string
    description = "prefix for the cloduwatch log group"
}

variable "retention_in_days" {
    type = number
    default = 90
    description = "number of days ot retain cloudwatch logs"
}