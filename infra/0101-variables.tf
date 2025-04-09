variable "aws_availability_zones" {
  type = list(any)
}
variable "aws_availability_zones_short" {
  type = list(any)
}

variable "ip_whitelist" {
  type = list(any)
}

variable "prefix" {}
variable "prefix_short" {}
variable "prefix_underscore" {}
variable "cloudwatch_namespace" {
  default = "DataWorkspace"
}
variable "cloudwatch_region" {
  default = "eu-west-2"
}
variable "mwaa_environment_name" {
  default = ""
}
variable "mwaa_source_bucket_name" {
  default = ""
}