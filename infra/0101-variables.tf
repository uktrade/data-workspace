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

variable "cloudwatch_subscription_filter" {}
variable "zendesk_email" {}
variable "zendesk_subdomain" {}
variable "zendesk_token" {}
variable "zendesk_service_field_id" {}
variable "zendesk_service_field_value" {}

variable "prometheus_whitelist" {
  type = list(any)
}
variable "metrics_service_discovery_basic_auth_user" {}
variable "metrics_service_discovery_basic_auth_password" {}

variable "google_analytics_site_id" {}

variable "gitlab_on" {
  type    = bool
  default = true
}
variable "gitlab_ip_whitelist" {
  type = list(any)
}
variable "gitlab_domain" {}
variable "gitlab_bucket" {}
variable "gitlab_instance_type" {}
variable "gitlab_memory" {}
variable "gitlab_cpu" {}
variable "gitlab_ebs_volume_size" {
  type    = number
  default = 1024
}
variable "gitlab_runner_instance_type" {}
variable "gitlab_runner_tap_instance_type" {}
variable "gitlab_runner_data_science_instance_type" {}
variable "gitlab_runner_ag_data_science_instance_type" {}
variable "gitlab_runner_root_volume_size" {}
variable "gitlab_runner_team_root_volume_size" {}
variable "gitlab_db_instance_class" {}
variable "gitlab_rds_cluster_instance_identifier" {
  default = ""
}
variable "gitlab_runner_visualisations_deployment_project_token" {}
variable "gitlab_runner_tap_project_token" {}
variable "gitlab_runner_data_science_project_token" {}
variable "gitlab_runner_ag_data_science_project_token" {}

variable "gitlab_sso_id" {}
variable "gitlab_sso_secret" {}
variable "gitlab_sso_domain" {}

variable "superset_on" {
  type    = bool
  default = true
}
variable "superset_admin_users" {}
variable "superset_db_instance_class" {}
variable "superset_internal_domain" {}

variable "superset_dw_user_username" {}
variable "superset_dw_user_password" {}

variable "airflow_on" {
  type    = bool
  default = true
}

variable "airflow_db_instance_class" {}
variable "airflow_domain" {}
variable "airflow_dag_processors" {
  type = list(object({
    name         = string,
    assume_roles = list(string),
    buckets      = list(string),
    keys         = list(string),
  }))
  default = []
}
variable "airflow_bucket_infix" {}

variable "dag_sync_github_key" {}
variable "github_ip_addresses" {
  type    = list(any)
  default = []
}

variable "datasets_rds_cluster_database_engine" {}
variable "datasets_rds_cluster_instance_parameter_group" {}
variable "datasets_rds_cluster_backup_retention_period" {}
variable "datasets_rds_cluster_database_name" {}
variable "datasets_rds_cluster_master_username" {}
variable "datasets_rds_cluster_storage_encryption_enabled" {}
variable "datasets_rds_cluster_cluster_identifier" {}
variable "datasets_rds_cluster_instance_class" {}
variable "datasets_rds_cluster_instance_performance_insights_enabled" {}
variable "datasets_rds_cluster_instance_identifier" {}
variable "datasets_rds_cluster_instance_monitoring_interval" {
  type    = number
  default = 0
}