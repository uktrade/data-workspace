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
