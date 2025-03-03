variable "aws_s3_bucket_notebook" {
  type        = any
  description = "S3 bucket for notebooks"
}

variable "account_id" {
  type        = string
  description = "account ID for the AWS account, dyanmic"
}

variable "prefix" {
  type        = string
  description = "Environment prefix"
}

variable "aws_region" {
  type = string
}
