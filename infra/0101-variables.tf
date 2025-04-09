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

variable "vpc_cidr" {}
variable "subnets_num_bits" {}
variable "vpc_notebooks_cidr" {}
variable "vpc_notebooks_subnets_num_bits" {}
variable "vpc_datasets_cidr" {}
variable "vpc_sagemaker_cidr" {}
variable "vpc_sagemaker_subnets_num_bits" {}

variable "aws_route53_zone" {}
variable "admin_domain" {}
variable "appstream_domain" {}
variable "support_domain" {}

variable "admin_db_instance_class" {}
variable "admin_db_instance_version" {}
variable "admin_db_instance_allocated_storage" {
  type    = number
  default = 200
}
variable "admin_db_instance_max_allocated_storage" {
  type    = number
  default = 400
}
variable "admin_authbroker_client_id" {}
variable "admin_authbroker_client_secret" {}
variable "admin_authbroker_url" {}
variable "admin_environment" {}
variable "admin_instances" {
  type    = number
  default = 2
}
variable "admin_deregistration_delay" {
  type    = number
  default = 300
}

variable "uploads_bucket" {}
variable "appstream_bucket" {}
variable "notebooks_bucket" {}
variable "notebooks_bucket_cors_domains" {
  type = list(string)
}
variable "notebook_container_image" {}
variable "superset_container_image" {}

variable "alb_access_logs_bucket" {}
variable "alb_logs_account" {}

variable "cloudwatch_destination_arn" {}
variable "cloudwatch_destination_datadog_arn" {
  type    = string
  default = ""
}

variable "mirrors_bucket_name" {}
variable "mirrors_data_bucket_name" {}
variable "mirrors_bucket_non_prod_account_ids" {
  type    = list(string)
  default = []
}

variable "sentry_dsn" {}
variable "sentry_notebooks_dsn" {}
variable "sentry_matchbox_dsn" {}
variable "sentry_environment" {}

variable "airflow_authbroker_client_id" {}
variable "airflow_authbroker_client_secret" {}
variable "airflow_authbroker_url" {}
variable "airflow_data_workspace_s3_import_hawk_id" {
  type    = string
  default = ""
}
variable "airflow_data_workspace_s3_import_hawk_key" {
  type    = string
  default = ""
}
variable "airflow_resource_endpoints" {
  type = list(object({
    arn  = string
    port = number
  }))
  default = []
}

variable "notebook_task_role_prefix" {}
variable "notebook_task_role_policy_name" {}

variable "healthcheck_domain" {}

variable "prometheus_domain" {}