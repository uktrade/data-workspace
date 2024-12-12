variable "prefix" {
    type = string
    description = "prefix for the cloduwatch log group"
    default = ""
}

variable "retention_in_days" {
    type = number
    default = 90
    description = "number of days ot retain cloudwatch logs"
}

variable "sagemaker_log_group" {
    type = string 
}

variable "lambda_function_arn" {
    type = string  
}