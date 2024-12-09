variable "account_id" {
  type        = string
  description = "AWS Account ID"
}

variable "aws_region" {
  type        = string
  description = "AWS Region in format e.g. us-west-1"
}

variable "s3_bucket_notebooks_arn" {
  type        = string
  description = "S3 Bucket for notebook user data storage"
}
