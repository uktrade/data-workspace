provider "aws" {}
provider "aws" {
  alias = "route53"
}
provider "aws" {
  alias = "mirror"
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
