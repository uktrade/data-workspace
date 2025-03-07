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


variable "prefix" {
  type        = string
  description = "Environment prefix"
}


variable "default_sagemaker_bucket_arn" {
  type        = string
  description = "Output of Sagemaker async"
}
