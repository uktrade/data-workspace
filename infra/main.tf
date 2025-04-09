provider "aws" {}
provider "aws" {
  alias = "route53"
}
provider "aws" {
  alias = "mirror"
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

variable "matchbox_db_instance_class" {
  type    = string
  default = ""
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

locals {
  admin_container_name   = "jupyterhub-admin"
  admin_container_port   = "8000"
  admin_container_memory = 2048
  admin_container_cpu    = 1024
  admin_alb_port         = "443"
  admin_api_path         = "/api/v1/databases"

  celery_container_memory = 8192
  celery_container_cpu    = 1024

  notebook_container_name     = "jupyterhub-notebook"
  notebook_container_port     = "8888"
  notebook_container_port_dev = "9000"

  notebook_container_memory = 8192
  notebook_container_cpu    = 1024

  user_provided_container_name   = "user-provided"
  user_provided_container_port   = "8888"
  user_provided_container_memory = 8192
  user_provided_container_cpu    = 1024

  logstash_container_name     = "jupyterhub-logstash"
  logstash_alb_port           = "443"
  logstash_container_memory   = 8192
  logstash_container_cpu      = 2048
  logstash_container_port     = "8889"
  logstash_container_api_port = "9600"

  dns_rewrite_proxy_container_name   = "jupyterhub-dns-rewrite-proxy"
  dns_rewrite_proxy_container_memory = 512
  dns_rewrite_proxy_container_cpu    = 256

  sentryproxy_container_name   = "jupyterhub-sentryproxy"
  sentryproxy_container_memory = 512
  sentryproxy_container_cpu    = 256

  mirrors_sync_container_name   = "jupyterhub-mirrors-sync"
  mirrors_sync_container_memory = 8192
  mirrors_sync_container_cpu    = 1024

  mirrors_sync_cran_binary_container_name   = "jupyterhub-mirrors-sync-cran-binary"
  mirrors_sync_cran_binary_container_memory = 2048
  mirrors_sync_cran_binary_container_cpu    = 1024

  healthcheck_container_port   = 8888
  healthcheck_container_name   = "healthcheck"
  healthcheck_alb_port         = "443"
  healthcheck_container_memory = 512
  healthcheck_container_cpu    = 256

  prometheus_container_port   = 9090
  prometheus_container_name   = "prometheus"
  prometheus_alb_port         = "443"
  prometheus_container_memory = 512
  prometheus_container_cpu    = 256

  superset_container_memory = 8192
  superset_container_cpu    = 1024

  airflow_container_memory = 2048
  airflow_container_cpu    = 1024

  flower_container_memory = 8192
  flower_container_cpu    = 1024

  arango_container_port = 8529

  mlflow_container_memory = 8192
  mlflow_container_cpu    = 1024
  mlflow_port             = 8004

  matchbox_container_memory = 8192
  matchbox_container_cpu    = 1024
  matchbox_api_port         = 8000
  matchbox_db_port          = 5432
}
