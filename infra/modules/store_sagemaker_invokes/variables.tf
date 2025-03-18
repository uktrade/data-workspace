variable "prefix" {
  type = string
}


variable "sagemaker_db_instance_allocated_storage" {
  type = number
}


variable "sagemaker_db_instance_max_allocated_storage" {
  type = number
}


variable "sagemaker_db_instance_version" {
  type = string
}


variable "sagemaker_db_instance_class" {
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


variable "vpc_id_main" {
  type = string
}


variable "aws_subnet_main" {
  type = list(string)
}


variable "notebooks_security_group_id" {
  type = string
}
