variable "prefix" {
  type = string
}


variable "aws_region" {
  type = string
}


variable "account_id" {
  type = string
}


variable "sns_success_topic_arn" {
  type = string
}


variable "sns_error_topic_arn" {
  type = string
}



variable "vpc_id_datasets" {
  type = string
}


variable "datasets_security_group_id" {
  type = string
}

variable "datasets_subnet_ids" {
  type = list(string)
}



variable "datasets_db_username" {
  type = string
}


variable "datasets_db_host" {
  type = string
}


variable "datasets_db_arn" {
  type = string
}


variable "datasets_db_secret_arn" {
  type = string
}


variable "datasets_db_port" {
  type = string
}


variable "datasets_db_name" {
  type = string
}


variable "notebooks_s3_bucket_arn" {
  type = string
}


variable "lambda_layer_pyscopg3_arn" {
  type = string
}
