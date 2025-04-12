resource "aws_ecs_service" "airflow_webserver" {
  count                             = var.airflow_on ? 1 : 0
  name                              = "${var.prefix}-airflow-webserver"
  cluster                           = aws_ecs_cluster.main_cluster.id
  task_definition                   = aws_ecs_task_definition.airflow_webserver[count.index].arn
  desired_count                     = 2
  launch_type                       = "FARGATE"
  deployment_maximum_percent        = 200
  platform_version                  = "1.4.0"
  health_check_grace_period_seconds = "10"

  network_configuration {
    subnets         = ["${aws_subnet.private_with_egress.*.id[0]}"]
    security_groups = ["${aws_security_group.airflow_webserver.id}"]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.airflow_webserver_8080[count.index].arn
    container_port   = "8080"
    container_name   = "airflow"
  }

  service_registries {
    registry_arn = aws_service_discovery_service.airflow[0].arn
  }

  depends_on = [
    aws_lb_listener.airflow_webserver_443,
  ]
}

resource "aws_service_discovery_service" "airflow" {
  count = var.airflow_on ? 1 : 0
  name  = "airflow"
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.jupyterhub.id
    dns_records {
      ttl  = 10
      type = "A"
    }
  }

  # Needed for a service to be able to register instances with a target group,
  # but only if it has a service_registries, which we do
  # https://forums.aws.amazon.com/thread.jspa?messageID=852407&tstart=0
  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_ecs_task_definition" "airflow_webserver" {
  count  = var.airflow_on ? 1 : 0
  family = "${var.prefix}-airflow-webserver"
  container_definitions = jsonencode([
    {
      "command"    = ["airflow", "webserver", "-p 8080"]
      "entryPoint" = ["/home/vcap/app/dataflow/bin/aws-wrapper-no-git-sync.sh"],
      "environment" = [
        {
          "name"  = "DB_HOST",
          "value" = aws_rds_cluster.airflow[count.index].endpoint,
        },
        {
          "name"  = "DB_NAME",
          "value" = aws_rds_cluster.airflow[count.index].database_name
        },
        {
          "name"  = "DB_PASSWORD",
          "value" = random_string.aws_db_instance_airflow_password.result
        },
        {
          "name"  = "DB_PORT",
          "value" = tostring(aws_rds_cluster.airflow[count.index].port)
        },
        {
          "name"  = "DB_USER",
          "value" = aws_rds_cluster.airflow[count.index].master_username
        },
        {
          "name"  = "AIRFLOW__WEBSERVER__SECRET_KEY",
          "value" = random_string.airflow_secret_key.result
        },
        {
          "name"  = "SENTRY_DSN",
          "value" = var.sentry_notebooks_dsn
        },
        {
          "name"  = "SENTRY_ENVIRONMENT",
          "value" = var.sentry_environment
        },
        {
          "name"  = "AUTHBROKER_URL",
          "value" = var.airflow_authbroker_url
        },
        {
          "name"  = "AUTHBROKER_CLIENT_ID",
          "value" = var.airflow_authbroker_client_id
        },
        {
          "name"  = "AUTHBROKER_CLIENT_SECRET",
          "value" = var.airflow_authbroker_client_secret
        },
        {
          "name"  = "DATASETS_DB_HOST",
          "value" = aws_rds_cluster.datasets.endpoint
        },
        {
          "name"  = "DATASETS_DB_NAME",
          "value" = aws_rds_cluster.datasets.database_name
        },
        {
          "name"  = "DATASETS_DB_PASSWORD",
          "value" = random_string.aws_rds_cluster_instance_datasets_password.result
        },
        {
          "name"  = "DATASETS_DB_PORT",
          "value" = tostring(aws_rds_cluster.datasets.port)
        },
        {
          "name"  = "DATASETS_DB_USER",
          "value" = var.datasets_rds_cluster_master_username
        },
        {
          "name"  = "AIRFLOW__AWS_ECS_EXECUTOR__REGION_NAME",
          "value" = "eu-west-2"
        },
        {
          "name"  = "AIRFLOW__AWS_ECS_EXECUTOR__SUBNETS",
          "value" = aws_subnet.private_with_egress.*.id[0]
        },
        {
          "name"  = "AIRFLOW__AWS_ECS_EXECUTOR__SECURITY_GROUPS",
          "value" = aws_security_group.airflow_webserver.id
        },
        {
          "name"  = "AIRFLOW__AWS_ECS_EXECUTOR__TASK_DEFINITION",
          "value" = aws_ecs_task_definition.airflow_dag_tasks[0].arn
        },
        {
          "name"  = "AIRFLOW__AWS_ECS_EXECUTOR__CLUSTER",
          "value" = aws_ecs_cluster.airflow_dag_tasks.name
        },
        {
          "name"  = "AIRFLOW__AWS_ECS_EXECUTOR__CONTAINER_NAME",
          "value" = "airflow"
        },
        {
          "name"  = "AIRFLOW__LOGGING__REMOTE_BASE_LOG_FOLDER",
          "value" = "cloudwatch://${aws_cloudwatch_log_group.airflow_dag_tasks_airflow_logging[0].arn}"
        },
        {
          # The key is already json-encoded, so to avoid it being double-json encoded, we decode it
          # first. But to do this we need to wrap it in double quotes so it's valid JSON.
          "name"  = "DAG_SYNC_GITHUB_KEY",
          "value" = jsondecode("\"${var.dag_sync_github_key}\"")
        },
        {
          "name"  = "DATA_WORKSPACE_S3_IMPORT_HAWK_ID",
          "value" = var.airflow_data_workspace_s3_import_hawk_id
        },
        {
          "name"  = "DATA_WORKSPACE_S3_IMPORT_HAWK_KEY",
          "value" = var.airflow_data_workspace_s3_import_hawk_key
        }
      ],
      "essential" = true,
      "image"     = "${aws_ecr_repository.airflow.repository_url}:master",
      "logConfiguration" = {
        "logDriver" = "awslogs",
        "options" = {
          "awslogs-group"         = aws_cloudwatch_log_group.airflow_webserver[count.index].name,
          "awslogs-region"        = data.aws_region.aws_region.name,
          "awslogs-stream-prefix" = "airflow"
        }
      },
      "networkMode"       = "awsvpc",
      "memoryReservation" = local.airflow_container_memory,
      "cpu"               = local.airflow_container_cpu,
      "mountPoints"       = [],
      "name"              = "airflow",
      "portMappings" = [
        {
          "containerPort" = 8080,
          "hostPort"      = 8080,
          "protocol"      = "tcp"
        },
      ]
    }
  ])

  execution_role_arn       = aws_iam_role.airflow_webserver_execution[count.index].arn
  task_role_arn            = aws_iam_role.airflow_webserver_task[count.index].arn
  network_mode             = "awsvpc"
  cpu                      = local.airflow_container_cpu
  memory                   = local.airflow_container_memory
  requires_compatibilities = ["FARGATE"]

  lifecycle {
    ignore_changes = [
      revision,
    ]
  }
}

resource "aws_cloudwatch_log_group" "airflow_webserver" {
  count             = var.airflow_on ? 1 : 0
  name              = "${var.prefix}-airflow-webserver"
  retention_in_days = "3653"
}

resource "aws_cloudwatch_log_subscription_filter" "airflow" {
  count           = var.cloudwatch_subscription_filter && var.airflow_on ? 1 : 0
  name            = "${var.prefix}-airflow"
  log_group_name  = aws_cloudwatch_log_group.airflow_webserver[count.index].name
  filter_pattern  = ""
  destination_arn = var.cloudwatch_destination_arn
}

resource "aws_iam_role" "airflow_webserver_execution" {
  count              = var.airflow_on ? 1 : 0
  name               = "${var.prefix}-airflow-webserver-execution"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.airflow_webserver_execution_ecs_tasks_assume_role[count.index].json
}

resource "aws_iam_role" "airflow_webserver_task" {
  count              = var.airflow_on ? 1 : 0
  name               = "${var.prefix}-airflow-webserver-task"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.airflow_webserver_task_ecs_tasks_assume_role[count.index].json
}

data "aws_iam_policy_document" "airflow_webserver_execution_ecs_tasks_assume_role" {
  count = var.airflow_on ? 1 : 0
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "airflow_webserver_execution" {
  count      = var.airflow_on ? 1 : 0
  role       = aws_iam_role.airflow_webserver_execution[count.index].name
  policy_arn = aws_iam_policy.airflow_webserver_execution[count.index].arn
}

resource "aws_iam_policy" "airflow_webserver_execution" {
  count  = var.airflow_on ? 1 : 0
  name   = "${var.prefix}-airflow-execution"
  path   = "/"
  policy = data.aws_iam_policy_document.airflow_webserver_execution[count.index].json
}

data "aws_iam_policy_document" "airflow_webserver_task_ecs_tasks_assume_role" {
  count = var.airflow_on ? 1 : 0
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "airflow_ecs" {
  count              = var.airflow_on ? 1 : 0
  name               = "${var.prefix}-airflow-ecs"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.airflow_ecs_assume_role[count.index].json
}

resource "aws_iam_role_policy_attachment" "airflow_ecs" {
  count      = var.airflow_on ? 1 : 0
  role       = aws_iam_role.airflow_ecs[count.index].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}

resource "aws_iam_role_policy_attachment" "airflow_webserver_task" {
  count      = var.airflow_on ? 1 : 0
  role       = aws_iam_role.airflow_webserver_task[count.index].name
  policy_arn = aws_iam_policy.airflow_webserver_task[0].arn
}

resource "aws_iam_policy" "airflow_webserver_task" {
  count  = var.airflow_on ? 1 : 0
  name   = "${var.prefix}-airflow-task"
  path   = "/"
  policy = data.aws_iam_policy_document.airflow_webserver_task[0].json
}

data "aws_iam_policy_document" "airflow_ecs_assume_role" {
  count = var.airflow_on ? 1 : 0
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}


data "aws_iam_policy_document" "airflow_webserver_execution" {
  count = var.airflow_on ? 1 : 0
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "${aws_cloudwatch_log_group.airflow_webserver[count.index].arn}:*",
    ]
  }

  statement {
    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]

    resources = [
      "${aws_ecr_repository.airflow.arn}",
    ]
  }

  statement {
    actions = [
      "ecr:GetAuthorizationToken",
    ]

    resources = [
      "*",
    ]
  }
}

data "aws_iam_policy_document" "airflow_webserver_task" {
  count = var.airflow_on ? 1 : 0

  # For viewing logs
  statement {
    actions = [
      "logs:GetLogEvents"
    ]

    # Should be tighter
    resources = [
      "*"
    ]
  }
}

resource "random_string" "airflow_secret_key" {
  length  = 64
  special = false
}
