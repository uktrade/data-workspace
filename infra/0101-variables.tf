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

variable "datasets_create_elastic_aws_service_linked_role" {
  type    = bool
  default = false
}

variable "paas_cidr_block" {}
variable "paas_vpc_id" {}
variable "quicksight_cidr_block" {}
variable "datasets_subnet_cidr_blocks" {
  type = list(any)
}
variable "dataset_subnets_availability_zones" {
  type = list(any)
}
variable "quicksight_security_group_name" {}
variable "quicksight_security_group_description" {}
variable "quicksight_subnet_availability_zone" {}
variable "quicksight_namespace" {}
variable "quicksight_user_region" {}
variable "quicksight_vpc_arn" {}
variable "quicksight_dashboard_group" {}
variable "quicksight_sso_url" {}
variable "quicksight_author_custom_permissions" {}
variable "quicksight_author_iam_arn" {}

variable "shared_keypair_public_key" {}

variable "flower_on" {
  type    = bool
  default = true
}
variable "flower_username" {}
variable "flower_password" {}


variable "mlflow_on" {
  type    = bool
  default = true
}
variable "mlflow_artifacts_bucket" {}
variable "mlflow_instances" {}
variable "mlflow_instances_long" {}
variable "mlflow_db_instance_class" {}

variable "jwt_public_key" {}
variable "jwt_private_key" {}

variable "arango_on" {
  type    = bool
  default = false
}

variable "arango_ebs_volume_size" { default = "" }
variable "arango_ebs_volume_type" { default = "" }
variable "arango_instance_type" { default = "" }
variable "arango_image_id" { default = "" }
variable "arango_container_memory" { default = 1024 }

variable "s3_prefixes_for_external_role_copy" {
  type    = list(string)
  default = ["import-data", "export-data"]
}

variable "teams_webhook_url" { default = "" }
variable "sagemaker_budget_emails" { default = [""] }

variable "sagemaker_on" {
  type    = bool
  default = false
}

variable "sagemaker_gpt_neo_125m" {
  type    = bool
  default = false
}

variable "sagemaker_flan_t5_780m" {
  type    = bool
  default = false
}

variable "sagemaker_phi_2_3b" {
  type    = bool
  default = false
}

variable "sagemaker_llama_3_3b" {
  type    = bool
  default = false
}

variable "sagemaker_llama_3_3b_instruct" {
  type    = bool
  default = false
}

variable "sagemaker_mistral_7b_instruct" {
  type    = bool
  default = false
}

variable "sagemaker_gpt_neo_125m_scale_up_cooldown" {
  type    = number
  default = 900
}
variable "sagemaker_flan_t3_780m_scaleup_cooldown" {
  type    = number
  default = 900
}

variable "sagemaker_phi_2_3b_scaleup_cooldown" {
  type    = number
  default = 900
}

variable "sagemaker_llama_3_3b_scaleup_cooldown" {
  type    = number
  default = 900
}

variable "sagemaker_llama_3_3b_instruct_scaleup_cooldown" {
  type    = number
  default = 900
}

variable "sagemaker_mistral_7b_instruct_scaleup_cooldown" {
  type    = number
  default = 900
}


variable "matchbox_on" {
  type    = bool
  default = false
}

variable "matchbox_dev_mode_on" {
  type    = bool
  default = false
}

variable "vpc_matchbox_cidr" {
  type    = string
  default = ""
}

variable "matchbox_instances" {
  type    = list(string)
  default = []
}

variable "matchbox_instances_long" {
  type    = list(string)
  default = []
}

variable "matchbox_api_container_resources" {
  description = "Map of specs to use when building the Matchbox API"
  type        = map(string)
  default = {
    cpu    = "1024"
    memory = "8192"
  }
}

variable "matchbox_db_instance_class" {
  type    = string
  default = ""
}

variable "matchbox_postgres_parameters" {
  description = "Map of PostgreSQL parameters to apply to the DB parameter group"
  type        = map(string)
  default = {
    statement_timeout = "600000"
  }
}

variable "vpc_matchbox_subnets_num_bits" {
  type    = string
  default = ""
}

variable "matchbox_s3_cache" {
  type    = string
  default = ""
}

variable "matchbox_s3_dev_artefacts" {
  type    = string
  default = ""
}

variable "matchbox_datadog_api_key" {
  type    = string
  default = ""
}

variable "matchbox_datadog_environment" {
  type    = string
  default = ""
}

variable "matchbox_api_key" {
  type    = string
  default = ""
}

variable "matchbox_github_source_url" {
  type    = string
  default = "https://github.com/uktrade/matchbox.git"
}

variable "codeconnection_arn" {
  type    = string
  default = ""
}

variable "matchbox_deploy_on_github_merge" {
  type    = bool
  default = false
}

variable "matchbox_deploy_on_github_merge_pattern" {
  type    = string
  default = "refs/heads/main"
}

variable "matchbox_deploy_on_github_release" {
  type    = bool
  default = false
}

variable "tools_github_source_url" {
  type    = string
  default = "https://github.com/uktrade/data-workspace-tools"
}

variable "tools" {
  type = list(object({
    name                   = string,
    docker_target          = string,
    codebuild_compute_type = string,
  }))
  default = [{
    name                   = "vscode",
    docker_target          = "python-vscode",
    codebuild_compute_type = "BUILD_GENERAL1_SMALL"
    }, {
    name                   = "jupyterlab-python",
    docker_target          = "python-jupyterlab",
    codebuild_compute_type = "BUILD_GENERAL1_SMALL"
    }, {
    name                   = "theia",
    docker_target          = "python-theia",
    codebuild_compute_type = "BUILD_GENERAL1_MEDIUM"
    }, {
    name                   = "pgadmin",
    docker_target          = "python-pgadmin",
    codebuild_compute_type = "BUILD_GENERAL1_SMALL"
    }, {
    name                   = "rstudio-rv4",
    docker_target          = "rv4-rstudio",
    codebuild_compute_type = "BUILD_GENERAL1_SMALL"
    }, {
    name                   = "remotedesktop",
    docker_target          = "remote-desktop",
    codebuild_compute_type = "BUILD_GENERAL1_SMALL"
  }]
}
