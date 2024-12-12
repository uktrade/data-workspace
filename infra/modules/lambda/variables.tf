variable "s3_bucket_name" {
    type = string
    description = "S3 bucket name for storing logs"
}

variable "log_delivery_role_arn" {
    type = string
    description = "ARN of the iAM role for Lambda"
}

variable "sagemaker_log_group_arn" {
    type = string
}