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

# variable "log_role_name" {
#   type = string
#   description = "name of the IAM role for log delivery"
# }

# variable "s3_bucket_arn" {
#   type = string
#   description = "arn of the s3 bucket for log storage"
# }