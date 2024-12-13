variable "prefix" {
  type        = string
  description = "Prefix for naming IAM resources"
}

variable "sagemaker_default_bucket_name" {
  type        = string
  description = "name of the default S3 bucket used by sagemaker"
}

variable "aws_s3_bucket_notebook" {
  type = any
  description = "S3 bucket for notebooks"
}


variable "s3_bucket_arn" {
  type = string
  description = "arn of the s3 bucket for log storage"
}

variable "account_id" {
  type = string
  description = "account ID for the AWS account, dyanmic"
}

variable "lambda_function_arn" {
  type = string
  

