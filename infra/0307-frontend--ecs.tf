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
    matchbox_client_api_root = "https://matchbox.${var.admin_domain}:8000"
    } : {
    matchbox_client_api_root = ""
    }
  )
}

locals {
  admin_container_definitions = <<-EOT
    [
      {
        "command": $${container_command},
        "cpu": $${container_cpu},
        "environment": [
          $${environment}
          {
            "name": "ADMIN_DB__HOST",
            "value": "$${admin_db__host}"
          },
          {
            "name": "ADMIN_DB__NAME",
            "value": "$${admin_db__name}"
          },
          {
            "name": "ADMIN_DB__PASSWORD",
            "value": "$${admin_db__password}"
          },
          {
            "name": "ADMIN_DB__PORT",
            "value": "$${admin_db__port}"
          },
          {
            "name": "ADMIN_DB__USER",
            "value": "$${admin_db__user}"
          },
          {
            "name": "DATA_DB__datasets_1__HOST",
            "value": "$${datasets_db__host}"
          },
          {
            "name": "DATA_DB__datasets_1__NAME",
            "value": "$${datasets_db__name}"
          },
          {
            "name": "DATA_DB__datasets_1__PASSWORD",
            "value": "$${datasets_db__password}"
          },
          {
            "name": "DATA_DB__datasets_1__PORT",
            "value": "$${datasets_db__port}"
          },
          {
            "name": "DATA_DB__datasets_1__USER",
            "value": "$${datasets_db__user}"
          },
          {
            "name": "DATASETS_DB_INSTANCE_ID",
            "value": "$${datasets_db__instance_id}"
          },
          {
            "name": "EXPLORER_CONNECTIONS",
            "value": "{\"datasets_1\":\"datasets_1\"}"
          },
          {
            "name": "EXPLORER_DEFAULT_CONNECTION",
            "value": "datasets_1"
          },
          {
            "name": "ARANGO_DB__HOST",
            "value": "$${arango_db__host}"
          },
          {
            "name": "ARANGO_DB__PORT",
            "value": "$${arango_db__port}"
          },
          {
            "name": "ARANGO_DB__USER",
            "value": "root"
          },
          {
            "name": "ARANGO_DB__PASSWORD",
            "value": "$${arango_db__password}"
          },
          {
            "name": "ARANGO_DB__PROTOCOL",
            "value": "https"
          },
          {
            "name": "ALLOWED_HOSTS__1",
            "value": "$${root_domain}"
          },
          {
            "name": "ALLOWED_HOSTS__2",
            "value": ".$${root_domain}"
          },
          {
            "name": "EFS_ID",
            "value": "$${efs_id}"
          },
          {
            "name": "S3_POLICY_DOCUMENT_TEMPLATE_BASE64",
            "value": "$${notebook_task_role__policy_document_template_base64}"
          },
          {
            "name": "S3_ASSUME_ROLE_POLICY_DOCUMENT_BASE64",
            "value": "$${notebook_task_role__assume_role_policy_document_base64}"
          },
          {
            "name": "S3_PERMISSIONS_BOUNDARY",
            "value": "$${notebook_task_role__permissions_boundary_arn}"
          },
          {
            "name": "S3_ROLE_PREFIX",
            "value": "$${notebook_task_role__role_prefix}"
          },
          {
            "name": "S3_POLICY_NAME",
            "value": "$${notebook_task_role__policy_name}"
          },
          {
            "name": "S3_PERMISSIONS_BOUNDARY_ARN",
            "value": "$${notebook_task_role__permissions_boundary_arn}"
          },
          {
            "name": "S3_NOTEBOOKS_BUCKET_ARN",
            "value": "$${notebook_task_role__s3_bucket_arn}"
          },
          {
            "name": "APPLICATION_TEMPLATES__3__HOST_BASENAME",
            "value": "pgadmin"
          },
          {
            "name": "APPLICATION_TEMPLATES__3__NICE_NAME",
            "value": "pgAdmin"
          },
          {
            "name": "APPLICATION_TEMPLATES__3__SPAWNER",
            "value": "FARGATE"
          },
          {
            "name": "APPLICATION_TEMPLATES__3__SPAWNER_TIME",
            "value": "120"
          },
          {
            "name": "APPLICATION_TEMPLATES__3__SPAWNER_OPTIONS__PLATFORM_VERSION",
            "value": "1.4.0"
          },
          {
            "name": "APPLICATION_TEMPLATES__3__SPAWNER_OPTIONS__CLUSTER_NAME",
            "value": "$${fargate_spawner__task_custer_name}"
          },
          {
            "name": "APPLICATION_TEMPLATES__3__SPAWNER_OPTIONS__DEFINITION_ARN",
            "value": "$${fargate_spawner__pgadmin_task_definition_arn}"
          },
          {
            "name": "APPLICATION_TEMPLATES__3__SPAWNER_OPTIONS__CONTAINER_NAME",
            "value": "jupyterhub-notebook"
          },
          {
            "name": "APPLICATION_TEMPLATES__3__SPAWNER_OPTIONS__SECURITY_GROUPS__1",
            "value": "$${fargate_spawner__task_security_group}"
          },
          {
            "name": "APPLICATION_TEMPLATES__3__SPAWNER_OPTIONS__SUBNETS__1",
            "value": "$${fargate_spawner__task_subnet}"
          },
          {
            "name": "APPLICATION_TEMPLATES__3__SPAWNER_OPTIONS__ENV__DISABLE_AUTH",
            "value": "true"
          },
          {
            "name": "APPLICATION_TEMPLATES__3__SPAWNER_OPTIONS__PORT",
            "value": "8888"
          },
          {
            "name": "APPLICATION_TEMPLATES__3__SPAWNER_OPTIONS__ROLE_PREFIX",
            "value": "$${notebook_task_role__role_prefix}"
          },
          {
            "name": "APPLICATION_TEMPLATES__3__SPAWNER_OPTIONS__POLICY_NAME",
            "value": "$${notebook_task_role__policy_name}"
          },
          {
            "name": "APPLICATION_TEMPLATES__3__SPAWNER_OPTIONS__PERMISSIONS_BOUNDARY_ARN",
            "value": "$${notebook_task_role__permissions_boundary_arn}"
          },
          {
            "name": "APPLICATION_TEMPLATES__3__SPAWNER_OPTIONS__POLICY_DOCUMENT_TEMPLATE_BASE64",
            "value": "$${notebook_task_role__policy_document_template_base64}"
          },
          {
            "name": "APPLICATION_TEMPLATES__3__SPAWNER_OPTIONS__ASSUME_ROLE_POLICY_DOCUMENT_BASE64",
            "value": "$${notebook_task_role__assume_role_policy_document_base64}"
          },
          {
            "name": "APPLICATION_TEMPLATES__3__SPAWNER_OPTIONS__S3_SYNC",
            "value": "true"
          },
          {
            "name": "APPLICATION_TEMPLATES__3__SPAWNER_OPTIONS__S3_REGION",
            "value": "eu-west-2"
          },
          {
            "name": "APPLICATION_TEMPLATES__3__SPAWNER_OPTIONS__S3_HOST",
            "value": "s3-eu-west-2.amazonaws.com"
          },
          {
            "name": "APPLICATION_TEMPLATES__3__SPAWNER_OPTIONS__S3_BUCKET",
            "value": "$${notebooks_bucket}"
          },
          {
            "name": "APPLICATION_TEMPLATES__5__HOST_BASENAME",
            "value": "jupyterlabpython"
          },
          {
            "name": "APPLICATION_TEMPLATES__5__NICE_NAME",
            "value": "JupyterLab Python"
          },
          {
            "name": "APPLICATION_TEMPLATES__5__SPAWNER",
            "value": "FARGATE"
          },
          {
            "name": "APPLICATION_TEMPLATES__5__SPAWNER_TIME",
            "value": "120"
          },
          {
            "name": "APPLICATION_TEMPLATES__5__SPAWNER_OPTIONS__PLATFORM_VERSION",
            "value": "1.4.0"
          },
          {
            "name": "APPLICATION_TEMPLATES__5__SPAWNER_OPTIONS__CLUSTER_NAME",
            "value": "$${fargate_spawner__task_custer_name}"
          },
          {
            "name": "APPLICATION_TEMPLATES__5__SPAWNER_OPTIONS__DEFINITION_ARN",
            "value": "$${fargate_spawner__jupyterlabpython_task_definition_arn}"
          },
          {
            "name": "APPLICATION_TEMPLATES__5__SPAWNER_OPTIONS__CONTAINER_NAME",
            "value": "jupyterhub-notebook"
          },
          {
            "name": "APPLICATION_TEMPLATES__5__SPAWNER_OPTIONS__SECURITY_GROUPS__1",
            "value": "$${fargate_spawner__task_security_group}"
          },
          {
            "name": "APPLICATION_TEMPLATES__5__SPAWNER_OPTIONS__SUBNETS__1",
            "value": "$${fargate_spawner__task_subnet}"
          },
          {
            "name": "APPLICATION_TEMPLATES__5__SPAWNER_OPTIONS__PORT",
            "value": "8888"
          },
          {
            "name": "APPLICATION_TEMPLATES__5__SPAWNER_OPTIONS__ROLE_PREFIX",
            "value": "$${notebook_task_role__role_prefix}"
          },
          {
            "name": "APPLICATION_TEMPLATES__5__SPAWNER_OPTIONS__POLICY_NAME",
            "value": "$${notebook_task_role__policy_name}"
          },
          {
            "name": "APPLICATION_TEMPLATES__5__SPAWNER_OPTIONS__PERMISSIONS_BOUNDARY_ARN",
            "value": "$${notebook_task_role__permissions_boundary_arn}"
          },
          {
            "name": "APPLICATION_TEMPLATES__5__SPAWNER_OPTIONS__POLICY_DOCUMENT_TEMPLATE_BASE64",
            "value": "$${notebook_task_role__policy_document_template_base64}"
          },
          {
            "name": "APPLICATION_TEMPLATES__5__SPAWNER_OPTIONS__ASSUME_ROLE_POLICY_DOCUMENT_BASE64",
            "value": "$${notebook_task_role__assume_role_policy_document_base64}"
          },
          {
            "name": "APPLICATION_TEMPLATES__5__SPAWNER_OPTIONS__S3_SYNC",
            "value": "true"
          },
          {
            "name": "APPLICATION_TEMPLATES__5__SPAWNER_OPTIONS__S3_REGION",
            "value": "eu-west-2"
          },
          {
            "name": "APPLICATION_TEMPLATES__5__SPAWNER_OPTIONS__S3_HOST",
            "value": "s3-eu-west-2.amazonaws.com"
          },
          {
            "name": "APPLICATION_TEMPLATES__5__SPAWNER_OPTIONS__S3_BUCKET",
            "value": "$${notebooks_bucket}"
          },
          {
            "name": "APPLICATION_TEMPLATES__9__HOST_BASENAME",
            "value": "remotedesktop"
          },
          {
            "name": "APPLICATION_TEMPLATES__9__NICE_NAME",
            "value": "Remote desktop"
          },
          {
            "name": "APPLICATION_TEMPLATES__9__SPAWNER",
            "value": "FARGATE"
          },
          {
            "name": "APPLICATION_TEMPLATES__9__SPAWNER_TIME",
            "value": "120"
          },
          {
            "name": "APPLICATION_TEMPLATES__9__SPAWNER_OPTIONS__CLUSTER_NAME",
            "value": "$${fargate_spawner__task_custer_name}"
          },
          {
            "name": "APPLICATION_TEMPLATES__9__SPAWNER_OPTIONS__DEFINITION_ARN",
            "value": "$${fargate_spawner__remotedesktop_task_definition_arn}"
          },
          {
            "name": "APPLICATION_TEMPLATES__9__SPAWNER_OPTIONS__CONTAINER_NAME",
            "value": "jupyterhub-notebook"
          },
          {
            "name": "APPLICATION_TEMPLATES__9__SPAWNER_OPTIONS__SECURITY_GROUPS__1",
            "value": "$${fargate_spawner__task_security_group}"
          },
          {
            "name": "APPLICATION_TEMPLATES__9__SPAWNER_OPTIONS__SUBNETS__1",
            "value": "$${fargate_spawner__task_subnet}"
          },
          {
            "name": "APPLICATION_TEMPLATES__9__SPAWNER_OPTIONS__ENV__DUMMY",
            "value": "value"
          },
          {
            "name": "APPLICATION_TEMPLATES__9__SPAWNER_OPTIONS__PORT",
            "value": "8888"
          },
          {
            "name": "APPLICATION_TEMPLATES__9__SPAWNER_OPTIONS__ROLE_PREFIX",
            "value": "$${notebook_task_role__role_prefix}"
          },
          {
            "name": "APPLICATION_TEMPLATES__9__SPAWNER_OPTIONS__POLICY_NAME",
            "value": "$${notebook_task_role__policy_name}"
          },
          {
            "name": "APPLICATION_TEMPLATES__9__SPAWNER_OPTIONS__PERMISSIONS_BOUNDARY_ARN",
            "value": "$${notebook_task_role__permissions_boundary_arn}"
          },
          {
            "name": "APPLICATION_TEMPLATES__9__SPAWNER_OPTIONS__POLICY_DOCUMENT_TEMPLATE_BASE64",
            "value": "$${notebook_task_role__policy_document_template_base64}"
          },
          {
            "name": "APPLICATION_TEMPLATES__9__SPAWNER_OPTIONS__ASSUME_ROLE_POLICY_DOCUMENT_BASE64",
            "value": "$${notebook_task_role__assume_role_policy_document_base64}"
          },
          {
            "name": "APPLICATION_TEMPLATES__9__SPAWNER_OPTIONS__S3_SYNC",
            "value": "true"
          },
          {
            "name": "APPLICATION_TEMPLATES__9__SPAWNER_OPTIONS__S3_REGION",
            "value": "eu-west-2"
          },
          {
            "name": "APPLICATION_TEMPLATES__9__SPAWNER_OPTIONS__S3_HOST",
            "value": "s3-eu-west-2.amazonaws.com"
          },
          {
            "name": "APPLICATION_TEMPLATES__9__SPAWNER_OPTIONS__S3_BUCKET",
            "value": "$${notebooks_bucket}"
          },
          {
            "name": "APPLICATION_TEMPLATES__9__SPAWNER_OPTIONS__PLATFORM_VERSION",
            "value": "1.4.0"
          },
          {
            "name": "APPLICATION_TEMPLATES__10__HOST_BASENAME",
            "value": "theia"
          },
          {
            "name": "APPLICATION_TEMPLATES__10__NICE_NAME",
            "value": "Theia"
          },
          {
            "name": "APPLICATION_TEMPLATES__10__SPAWNER",
            "value": "FARGATE"
          },
          {
            "name": "APPLICATION_TEMPLATES__10__SPAWNER_TIME",
            "value": "120"
          },
          {
            "name": "APPLICATION_TEMPLATES__10__SPAWNER_OPTIONS__PLATFORM_VERSION",
            "value": "1.4.0"
          },
          {
            "name": "APPLICATION_TEMPLATES__10__SPAWNER_OPTIONS__CLUSTER_NAME",
            "value": "$${fargate_spawner__task_custer_name}"
          },
          {
            "name": "APPLICATION_TEMPLATES__10__SPAWNER_OPTIONS__DEFINITION_ARN",
            "value": "$${fargate_spawner__theia_task_definition_arn}"
          },
          {
            "name": "APPLICATION_TEMPLATES__10__SPAWNER_OPTIONS__CONTAINER_NAME",
            "value": "jupyterhub-notebook"
          },
          {
            "name": "APPLICATION_TEMPLATES__10__SPAWNER_OPTIONS__SECURITY_GROUPS__1",
            "value": "$${fargate_spawner__task_security_group}"
          },
          {
            "name": "APPLICATION_TEMPLATES__10__SPAWNER_OPTIONS__SUBNETS__1",
            "value": "$${fargate_spawner__task_subnet}"
          },
          {
            "name": "APPLICATION_TEMPLATES__10__SPAWNER_OPTIONS__ENV__DUMMY",
            "value": "value"
          },
          {
            "name": "APPLICATION_TEMPLATES__10__SPAWNER_OPTIONS__PORT",
            "value": "8888"
          },
          {
            "name": "APPLICATION_TEMPLATES__10__SPAWNER_OPTIONS__ROLE_PREFIX",
            "value": "$${notebook_task_role__role_prefix}"
          },
          {
            "name": "APPLICATION_TEMPLATES__10__SPAWNER_OPTIONS__POLICY_NAME",
            "value": "$${notebook_task_role__policy_name}"
          },
          {
            "name": "APPLICATION_TEMPLATES__10__SPAWNER_OPTIONS__PERMISSIONS_BOUNDARY_ARN",
            "value": "$${notebook_task_role__permissions_boundary_arn}"
          },
          {
            "name": "APPLICATION_TEMPLATES__10__SPAWNER_OPTIONS__POLICY_DOCUMENT_TEMPLATE_BASE64",
            "value": "$${notebook_task_role__policy_document_template_base64}"
          },
          {
            "name": "APPLICATION_TEMPLATES__10__SPAWNER_OPTIONS__ASSUME_ROLE_POLICY_DOCUMENT_BASE64",
            "value": "$${notebook_task_role__assume_role_policy_document_base64}"
          },
          {
            "name": "APPLICATION_TEMPLATES__10__SPAWNER_OPTIONS__S3_SYNC",
            "value": "true"
          },
          {
            "name": "APPLICATION_TEMPLATES__10__SPAWNER_OPTIONS__S3_REGION",
            "value": "eu-west-2"
          },
          {
            "name": "APPLICATION_TEMPLATES__10__SPAWNER_OPTIONS__S3_HOST",
            "value": "s3-eu-west-2.amazonaws.com"
          },
          {
            "name": "APPLICATION_TEMPLATES__10__SPAWNER_OPTIONS__S3_BUCKET",
            "value": "$${notebooks_bucket}"
          },
          {
            "name": "APPLICATION_TEMPLATES__12__HOST_BASENAME",
            "value": "rstudio-rv4"
          },
          {
            "name": "APPLICATION_TEMPLATES__12__NICE_NAME",
            "value": "RStudio (R version 4)"
          },
          {
            "name": "APPLICATION_TEMPLATES__12__SPAWNER",
            "value": "FARGATE"
          },
          {
            "name": "APPLICATION_TEMPLATES__12__SPAWNER_TIME",
            "value": "120"
          },
          {
            "name": "APPLICATION_TEMPLATES__12__SPAWNER_OPTIONS__CLUSTER_NAME",
            "value": "$${fargate_spawner__task_custer_name}"
          },
          {
            "name": "APPLICATION_TEMPLATES__12__SPAWNER_OPTIONS__DEFINITION_ARN",
            "value": "$${fargate_spawner__rstudio_rv4_task_definition_arn}"
          },
          {
            "name": "APPLICATION_TEMPLATES__12__SPAWNER_OPTIONS__CONTAINER_NAME",
            "value": "jupyterhub-notebook"
          },
          {
            "name": "APPLICATION_TEMPLATES__12__SPAWNER_OPTIONS__SECURITY_GROUPS__1",
            "value": "$${fargate_spawner__task_security_group}"
          },
          {
            "name": "APPLICATION_TEMPLATES__12__SPAWNER_OPTIONS__SUBNETS__1",
            "value": "$${fargate_spawner__task_subnet}"
          },
          {
            "name": "APPLICATION_TEMPLATES__12__SPAWNER_OPTIONS__ENV__DUMMY",
            "value": "value"
          },
          {
            "name": "APPLICATION_TEMPLATES__12__SPAWNER_OPTIONS__PORT",
            "value": "8888"
          },
          {
            "name": "APPLICATION_TEMPLATES__12__SPAWNER_OPTIONS__ROLE_PREFIX",
            "value": "$${notebook_task_role__role_prefix}"
          },
          {
            "name": "APPLICATION_TEMPLATES__12__SPAWNER_OPTIONS__POLICY_NAME",
            "value": "$${notebook_task_role__policy_name}"
          },
          {
            "name": "APPLICATION_TEMPLATES__12__SPAWNER_OPTIONS__PERMISSIONS_BOUNDARY_ARN",
            "value": "$${notebook_task_role__permissions_boundary_arn}"
          },
          {
            "name": "APPLICATION_TEMPLATES__12__SPAWNER_OPTIONS__POLICY_DOCUMENT_TEMPLATE_BASE64",
            "value": "$${notebook_task_role__policy_document_template_base64}"
          },
          {
            "name": "APPLICATION_TEMPLATES__12__SPAWNER_OPTIONS__ASSUME_ROLE_POLICY_DOCUMENT_BASE64",
            "value": "$${notebook_task_role__assume_role_policy_document_base64}"
          },
          {
            "name": "APPLICATION_TEMPLATES__12__SPAWNER_OPTIONS__S3_SYNC",
            "value": "true"
          },
          {
            "name": "APPLICATION_TEMPLATES__12__SPAWNER_OPTIONS__S3_REGION",
            "value": "eu-west-2"
          },
          {
            "name": "APPLICATION_TEMPLATES__12__SPAWNER_OPTIONS__S3_HOST",
            "value": "s3-eu-west-2.amazonaws.com"
          },
          {
            "name": "APPLICATION_TEMPLATES__12__SPAWNER_OPTIONS__S3_BUCKET",
            "value": "$${notebooks_bucket}"
          },
          {
            "name": "APPLICATION_TEMPLATES__12__SPAWNER_OPTIONS__PLATFORM_VERSION",
            "value": "1.4.0"
          },
          {
            "name": "APPLICATION_TEMPLATES__13__HOST_BASENAME",
            "value": "vscode"
          },
          {
            "name": "APPLICATION_TEMPLATES__13__NICE_NAME",
            "value": "VS Code"
          },
          {
            "name": "APPLICATION_TEMPLATES__13__SPAWNER",
            "value": "FARGATE"
          },
          {
            "name": "APPLICATION_TEMPLATES__13__SPAWNER_TIME",
            "value": "120"
          },
          {
            "name": "APPLICATION_TEMPLATES__13__SPAWNER_OPTIONS__PLATFORM_VERSION",
            "value": "1.4.0"
          },
          {
            "name": "APPLICATION_TEMPLATES__13__SPAWNER_OPTIONS__CLUSTER_NAME",
            "value": "$${fargate_spawner__task_custer_name}"
          },
          {
            "name": "APPLICATION_TEMPLATES__13__SPAWNER_OPTIONS__DEFINITION_ARN",
            "value": "$${fargate_spawner__vscode_task_definition_arn}"
          },
          {
            "name": "APPLICATION_TEMPLATES__13__SPAWNER_OPTIONS__CONTAINER_NAME",
            "value": "jupyterhub-notebook"
          },
          {
            "name": "APPLICATION_TEMPLATES__13__SPAWNER_OPTIONS__SECURITY_GROUPS__1",
            "value": "$${fargate_spawner__task_security_group}"
          },
          {
            "name": "APPLICATION_TEMPLATES__13__SPAWNER_OPTIONS__SUBNETS__1",
            "value": "$${fargate_spawner__task_subnet}"
          },
          {
            "name": "APPLICATION_TEMPLATES__13__SPAWNER_OPTIONS__ENV__DUMMY",
            "value": "value"
          },
          {
            "name": "APPLICATION_TEMPLATES__13__SPAWNER_OPTIONS__PORT",
            "value": "8888"
          },
          {
            "name": "APPLICATION_TEMPLATES__13__SPAWNER_OPTIONS__ROLE_PREFIX",
            "value": "$${notebook_task_role__role_prefix}"
          },
          {
            "name": "APPLICATION_TEMPLATES__13__SPAWNER_OPTIONS__POLICY_NAME",
            "value": "$${notebook_task_role__policy_name}"
          },
          {
            "name": "APPLICATION_TEMPLATES__13__SPAWNER_OPTIONS__PERMISSIONS_BOUNDARY_ARN",
            "value": "$${notebook_task_role__permissions_boundary_arn}"
          },
          {
            "name": "APPLICATION_TEMPLATES__13__SPAWNER_OPTIONS__POLICY_DOCUMENT_TEMPLATE_BASE64",
            "value": "$${notebook_task_role__policy_document_template_base64}"
          },
          {
            "name": "APPLICATION_TEMPLATES__13__SPAWNER_OPTIONS__ASSUME_ROLE_POLICY_DOCUMENT_BASE64",
            "value": "$${notebook_task_role__assume_role_policy_document_base64}"
          },
          {
            "name": "APPLICATION_TEMPLATES__13__SPAWNER_OPTIONS__S3_SYNC",
            "value": "true"
          },
          {
            "name": "APPLICATION_TEMPLATES__13__SPAWNER_OPTIONS__S3_REGION",
            "value": "eu-west-2"
          },
          {
            "name": "APPLICATION_TEMPLATES__13__SPAWNER_OPTIONS__S3_HOST",
            "value": "s3-eu-west-2.amazonaws.com"
          },
          {
            "name": "APPLICATION_TEMPLATES__13__SPAWNER_OPTIONS__S3_BUCKET",
            "value": "$${notebooks_bucket}"
          },
          {
            "name": "APPLICATION_SPAWNER_OPTIONS__FARGATE__VISUALISATION__ECR_REPOSITORY_NAME",
            "value": "$${fargate_spawner__user_provided_ecr_repository__name}"
          },
          {
            "name": "APPLICATION_SPAWNER_OPTIONS__FARGATE__VISUALISATION__POLICY_NAME",
            "value": "$${notebook_task_role__policy_name}"
          },
          {
            "name": "APPLICATION_SPAWNER_OPTIONS__FARGATE__VISUALISATION__CLUSTER_NAME",
            "value": "$${fargate_spawner__task_custer_name}"
          },
          {
            "name": "APPLICATION_SPAWNER_OPTIONS__FARGATE__VISUALISATION__DEFINITION_ARN",
            "value": "$${fargate_spawner__user_provided_task_definition_arn}"
          },
          {
            "name": "APPLICATION_SPAWNER_OPTIONS__FARGATE__VISUALISATION__CONTAINER_NAME",
            "value": "user-provided"
          },
          {
            "name": "APPLICATION_SPAWNER_OPTIONS__FARGATE__VISUALISATION__PORT",
            "value": "8888"
          },
          {
            "name": "APPLICATION_SPAWNER_OPTIONS__FARGATE__VISUALISATION__ASSUME_ROLE_POLICY_DOCUMENT_BASE64",
            "value": "$${notebook_task_role__assume_role_policy_document_base64}"
          },
          {
            "name": "APPLICATION_SPAWNER_OPTIONS__FARGATE__VISUALISATION__POLICY_DOCUMENT_TEMPLATE_BASE64",
            "value": "$${fargate_spawner__user_provided_task_role__policy_document_template_base64}"
          },
          {
            "name": "APPLICATION_SPAWNER_OPTIONS__FARGATE__VISUALISATION__PERMISSIONS_BOUNDARY_ARN",
            "value": "$${notebook_task_role__permissions_boundary_arn}"
          },
          {
            "name": "APPLICATION_SPAWNER_OPTIONS__FARGATE__VISUALISATION__SECURITY_GROUPS__1",
            "value": "$${fargate_spawner__task_security_group}"
          },
          {
            "name": "APPLICATION_SPAWNER_OPTIONS__FARGATE__VISUALISATION__SUBNETS__1",
            "value": "$${fargate_spawner__task_subnet}"
          },
          {
            "name": "APPLICATION_SPAWNER_OPTIONS__FARGATE__VISUALISATION__S3_SYNC",
            "value": "False"
          },
          {
            "name": "APPLICATION_SPAWNER_OPTIONS__FARGATE__VISUALISATION__S3_HOST",
            "value": "s3-eu-west-2.amazonaws.com"
          },
          {
            "name": "APPLICATION_SPAWNER_OPTIONS__FARGATE__VISUALISATION__S3_BUCKET",
            "value": "$${notebooks_bucket}"
          },
          {
            "name": "APPLICATION_SPAWNER_OPTIONS__FARGATE__VISUALISATION__S3_REGION",
            "value": "eu-west-2"
          },
          {
            "name": "APPLICATION_SPAWNER_OPTIONS__FARGATE__TOOL__MATCHBOX_CLIENT_API_ROOT",
            "value": "$${matchbox_client_api_root}"
          },
          {
            "name": "APPLICATION_ROOT_DOMAIN",
            "value": "$${root_domain}"
          },
          {
            "name": "SUPERSET_ROOT",
            "value": "$${superset_root}"
          },
          {
            "name": "SUPERSET_DW_USER_USERNAME",
            "value": "$${superset_dw_user_username}"
          },
          {
            "name": "SUPERSET_DW_USER_PASSWORD",
            "value": "$${superset_dw_user_password}"
          },
          {
            "name": "APPSTREAM_URL",
            "value": "$${appstream_url}"
          },
          {
            "name": "AUTHBROKER_CLIENT_ID",
            "value": "$${authbroker_client_id}"
          },
          {
            "name": "AUTHBROKER_CLIENT_SECRET",
            "value": "$${authbroker_client_secret}"
          },
          {
            "name": "AUTHBROKER_URL",
            "value": "$${authbroker_url}"
          },
          {
            "name": "NOTEBOOKS_BUCKET",
            "value": "$${notebooks_bucket}"
          },
          {
            "name": "REDIS_URL",
            "value": "$${redis_url}"
          },
          {
            "name": "SECRET_KEY",
            "value": "$${secret_key}"
          },
          {
            "name": "SUPPORT_URL",
            "value": "$${support_url}"
          },
          {
            "name": "UPLOADS_BUCKET",
            "value": "$${uploads_bucket}"
          },
          {
            "name": "MIRROR_REMOTE_ROOT",
            "value": "$${mirror_remote_root}"
          },
          {
            "name": "ZENDESK_EMAIL",
            "value": "$${zendesk_email}"
          },
          {
            "name": "ZENDESK_SUBDOMAIN",
            "value": "$${zendesk_subdomain}"
          },
          {
            "name": "ZENDESK_TOKEN",
            "value": "$${zendesk_token}"
          },
          {
            "name": "ZENDESK_SERVICE_FIELD_ID",
            "value": "$${zendesk_service_field_id}"
          },
          {
            "name": "ZENDESK_SERVICE_FIELD_VALUE",
            "value": "$${zendesk_service_field_value}"
          },
          {
            "name": "QUICKSIGHT_NAMESPACE",
            "value": "$${quicksight_namespace}"
          },
          {
            "name": "QUICKSIGHT_USER_REGION",
            "value": "$${quicksight_user_region}"
          },
          {
            "name": "QUICKSIGHT_VPC_ARN",
            "value": "$${quicksight_vpc_arn}"
          },
          {
            "name": "QUICKSIGHT_DASHBOARD_GROUP",
            "value": "$${quicksight_dashboard_group}"
          },
          {
            "name": "QUICKSIGHT_AUTHOR_CUSTOM_PERMISSIONS",
            "value": "$${quicksight_author_custom_permissions}"
          },
          {
            "name": "QUICKSIGHT_AUTHOR_IAM_ARN",
            "value": "$${quicksight_author_iam_arn}"
          },
          {
            "name": "QUICKSIGHT_SSO_URL",
            "value": "$${quicksight_sso_url}"
          },
          {
            "name": "QUICKSIGHT_DASHBOARD_EMBEDDING_ROLE_ARN",
            "value": "$${admin_dashboard_embedding_role_arn}"
          },
          {
            "name": "PROMETHEUS_DOMAIN",
            "value": "$${prometheus_domain}"
          },
          {
            "name": "METRICS_SERVICE_DISCOVERY_BASIC_AUTH_USER",
            "value": "$${metrics_service_discovery_basic_auth_user}"
          }, {
          "name": "METRICS_SERVICE_DISCOVERY_BASIC_AUTH_PASSWORD",
          "value": "$${metrics_service_discovery_basic_auth_password}"
          }, {
          "name": "GOOGLE_ANALYTICS_SITE_ID",
          "value": "$${google_analytics_site_id}"
          }, {
          "name": "X_FORWARDED_FOR_TRUSTED_HOPS",
          "value": "2"      
          }, {
          "name": "VISUALISATION_CLOUDWATCH_LOG_GROUP",
          "value": "$${visualisation_cloudwatch_log_group}"
          }, {
          "name": "FLOWER_ROOT",
          "value": "$${flower_root}"
          }, {
          "name": "JWT_PRIVATE_KEY",
          "value": "$${jwt_private_key}"
          }, {
          "name": "MLFLOW_PORT",
          "value": "$${mlflow_port}"
          }
        ],
        "essential": true,
        "image": "$${container_image}",
        "logConfiguration": {
          "logDriver": "awslogs",
          "options": {
            "awslogs-group": "$${log_group}",
            "awslogs-region": "$${log_region}",
            "awslogs-stream-prefix": "$${container_name}"
          }
        },
        "mountPoints": [],
        "name": "$${container_name}",
        "portMappings": [{
          "containerPort": $${container_port},
          "hostPort": $${container_port},
          "protocol": "tcp"
        }],
        "ulimits": [{
          "softLimit": 4096,
          "hardLimit": 4096,
          "name": "nofile"
        }],
        "volumesFrom": []
      }
    ]
  EOT
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
