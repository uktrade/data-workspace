locals {
  admin_container_vars = merge({
    container_image = "${aws_ecr_repository.admin.repository_url}:${data.external.admin_current_tag.result.tag}"
    container_name  = "${local.admin_container_name}"
    container_port  = "${local.admin_container_port}"
    container_cpu   = "${local.admin_container_cpu}"

    log_group  = "${aws_cloudwatch_log_group.admin.name}"
    log_region = "${data.aws_region.aws_region.name}"

    root_domain              = "${var.admin_domain}"
    admin_db__host           = "${aws_db_instance.admin.address}"
    admin_db__name           = "${aws_db_instance.admin.db_name}"
    admin_db__password       = "${random_string.aws_db_instance_admin_password.result}"
    admin_db__port           = "${aws_db_instance.admin.port}"
    admin_db__user           = "${aws_db_instance.admin.username}"
    datasets_db__host        = "${aws_rds_cluster_instance.datasets.endpoint}"
    datasets_db__name        = "${aws_rds_cluster.datasets.database_name}"
    datasets_db__password    = "${random_string.aws_rds_cluster_instance_datasets_password.result}"
    datasets_db__port        = "${aws_rds_cluster_instance.datasets.port}"
    datasets_db__user        = "${aws_rds_cluster.datasets.master_username}"
    datasets_db__instance_id = "${aws_rds_cluster_instance.datasets.identifier}"
    authbroker_client_id     = "${var.admin_authbroker_client_id}"
    authbroker_client_secret = "${var.admin_authbroker_client_secret}"
    authbroker_url           = "${var.admin_authbroker_url}"
    secret_key               = "${random_string.admin_secret_key.result}"

    environment = "${var.admin_environment}"

    uploads_bucket     = "${var.uploads_bucket}"
    notebooks_bucket   = "${var.notebooks_bucket}"
    mirror_remote_root = "https://s3-${data.aws_region.aws_region.name}.amazonaws.com/${var.mirrors_data_bucket_name != "" ? var.mirrors_data_bucket_name : var.mirrors_bucket_name}/"

    appstream_url = "https://${var.appstream_domain}/"
    support_url   = "https://${var.support_domain}/"

    redis_url = "redis://${aws_elasticache_cluster.admin.cache_nodes.0.address}:6379"

    sentry_dsn = "${var.sentry_dsn}"

    notebook_task_role__role_prefix                        = "${var.notebook_task_role_prefix}"
    notebook_task_role__permissions_boundary_arn           = "${aws_iam_policy.notebook_task_boundary.arn}"
    notebook_task_role__assume_role_policy_document_base64 = "${base64encode(data.aws_iam_policy_document.notebook_s3_access_ecs_tasks_assume_role.json)}"
    notebook_task_role__policy_name                        = "${var.notebook_task_role_policy_name}"
    notebook_task_role__policy_document_template_base64    = "${base64encode(data.aws_iam_policy_document.notebook_s3_access_template.json)}"
    notebook_task_role__s3_bucket_arn                      = "${aws_s3_bucket.notebooks.arn}"
    fargate_spawner__aws_region                            = "${data.aws_region.aws_region.name}"
    fargate_spawner__aws_ecs_host                          = "ecs.${data.aws_region.aws_region.name}.amazonaws.com"
    fargate_spawner__notebook_port                         = "${local.notebook_container_port}"
    fargate_spawner__task_custer_name                      = "${aws_ecs_cluster.notebooks.name}"
    fargate_spawner__task_container_name                   = "${local.notebook_container_name}"
    fargate_spawner__task_security_group                   = "${aws_security_group.notebooks.id}"
    fargate_spawner__task_subnet                           = "${aws_subnet.private_without_egress.*.id[0]}"

    fargate_spawner__jupyterlabpython_task_definition_arn = "${aws_ecs_task_definition.tools[1].family}"
    fargate_spawner__rstudio_rv4_task_definition_arn      = "${aws_ecs_task_definition.tools[4].family}"
    fargate_spawner__pgadmin_task_definition_arn          = "${aws_ecs_task_definition.tools[3].family}"
    fargate_spawner__remotedesktop_task_definition_arn    = "${aws_ecs_task_definition.tools[5].family}"
    fargate_spawner__theia_task_definition_arn            = "${aws_ecs_task_definition.tools[2].family}"
    fargate_spawner__vscode_task_definition_arn           = "${aws_ecs_task_definition.tools[0].family}"

    fargate_spawner__user_provided_task_definition_arn                        = "${aws_ecs_task_definition.user_provided.family}"
    fargate_spawner__user_provided_task_role__policy_document_template_base64 = "${base64encode(data.aws_iam_policy_document.user_provided_access_template.json)}"
    fargate_spawner__user_provided_ecr_repository__name                       = "${aws_ecr_repository.user_provided.name}"

    zendesk_email               = "${var.zendesk_email}"
    zendesk_subdomain           = "${var.zendesk_subdomain}"
    zendesk_token               = "${var.zendesk_token}"
    zendesk_service_field_id    = "${var.zendesk_service_field_id}"
    zendesk_service_field_value = "${var.zendesk_service_field_value}"

    prometheus_domain                             = "${var.prometheus_domain}"
    metrics_service_discovery_basic_auth_user     = "${var.metrics_service_discovery_basic_auth_user}"
    metrics_service_discovery_basic_auth_password = "${var.metrics_service_discovery_basic_auth_password}"

    google_analytics_site_id = "${var.google_analytics_site_id}"

    superset_root             = "https://${var.superset_internal_domain}"
    superset_dw_user_username = "${var.superset_dw_user_username}"
    superset_dw_user_password = "${var.superset_dw_user_password}"

    quicksight_namespace                 = "${var.quicksight_namespace}"
    quicksight_user_region               = "${var.quicksight_user_region}"
    quicksight_vpc_arn                   = "${var.quicksight_vpc_arn}"
    quicksight_dashboard_group           = "${var.quicksight_dashboard_group}"
    quicksight_author_custom_permissions = "${var.quicksight_author_custom_permissions}"
    quicksight_author_iam_arn            = "${var.quicksight_author_iam_arn}"
    quicksight_sso_url                   = "${var.quicksight_sso_url}"
    admin_dashboard_embedding_role_arn   = "${aws_iam_role.admin_dashboard_embedding.arn}"

    efs_id = "${aws_efs_file_system.notebooks.id}"

    visualisation_cloudwatch_log_group = "${aws_cloudwatch_log_group.notebook.name}"

    flower_root = "http://${aws_lb.flower.dns_name}"

    jwt_private_key = "${var.jwt_private_key}"
    mlflow_port     = "${local.mlflow_port}"
    }, var.arango_on ? {
    arango_db__host     = "${aws_route53_record.arango[0].name}"
    arango_db__password = "${random_string.aws_arangodb_root_password[0].result}"
    arango_db__port     = "${local.arango_container_port}"
    } : {
    arango_db__host     = ""
    arango_db__password = ""
    arango_db__port     = ""
    }, var.matchbox_on ? {
    matchbox_client_api_root = "http://matchbox.${var.admin_domain}:8000"
    } : {
    matchbox_client_api_root = ""
    }
  )
}

data "external" "admin_current_tag" {
  program = ["${path.module}/container-tag.sh"]

  query = {
    cluster_name   = "${aws_ecs_cluster.main_cluster.name}"
    service_name   = "${var.prefix}-admin" # Manually specified to avoid a cycle
    container_name = "jupyterhub-admin"
  }
}

resource "random_string" "admin_secret_key" {
  length  = 256
  special = false
}
