resource "aws_ecs_service" "airflow_dag_processor" {
  count                      = var.airflow_on ? length(var.airflow_dag_processors) : 0
  name                       = "${var.prefix}-airflow-dag-processor-${var.airflow_dag_processors[count.index].name}"
  cluster                    = aws_ecs_cluster.main_cluster.id
  task_definition            = aws_ecs_task_definition.airflow_dag_processor_service[count.index].arn
  desired_count              = 1
  launch_type                = "FARGATE"
  deployment_maximum_percent = 200
  platform_version           = "1.4.0"

  network_configuration {
    subnets         = ["${aws_subnet.private_with_egress.*.id[0]}"]
    security_groups = ["${aws_security_group.airflow_dag_processor_service.id}"]
  }

}

locals {
  airflow_team_role_prefix = "${var.prefix}-airflow-team-"
  airflow_dag_processor_container_vars = [
    for i, v in var.airflow_dag_processors : {
      command = "[\"/home/vcap/app/dataflow/bin/aws-dag-processor.sh\"]"

      container_image = "${aws_ecr_repository.airflow.repository_url}:master"
      container_name  = "airflow-dag-processor"
      log_group       = "${aws_cloudwatch_log_group.airflow_dag_processor[i].name}"
      log_region      = "${data.aws_region.aws_region.name}"
      cpu             = local.airflow_container_cpu
      memory          = local.airflow_container_memory

      db_host     = "${aws_rds_cluster.airflow[0].endpoint}"
      db_name     = "${aws_rds_cluster.airflow[0].database_name}"
      db_password = "${random_string.aws_db_instance_airflow_password.result}"
      db_port     = "${aws_rds_cluster.airflow[0].port}"
      db_user     = "${aws_rds_cluster.airflow[0].master_username}"
      secret_key  = "${random_string.airflow_secret_key.result}"

      datasets_db_host     = "${aws_rds_cluster.datasets.endpoint}"
      datasets_db_name     = "${aws_rds_cluster.datasets.database_name}"
      datasets_db_password = "${random_string.aws_rds_cluster_instance_datasets_password.result}"
      datasets_db_port     = "${aws_rds_cluster.datasets.port}"
      datasets_db_user     = "${var.datasets_rds_cluster_master_username}"

      sentry_dsn         = "${var.sentry_notebooks_dsn}"
      sentry_environment = "${var.sentry_environment}"

      cloudwatch_log_group_arn = "${aws_cloudwatch_log_group.airflow_dag_tasks_airflow_logging[0].arn}"

      team                = "${v.name}"
      team_secret_id      = "${var.prefix}/airflow/${v.name}"
      dag_sync_github_key = "${var.dag_sync_github_key}"
    }
  ]
}

resource "aws_ecs_task_definition" "airflow_dag_processor_service" {
  count  = var.airflow_on ? length(var.airflow_dag_processors) : 0
  family = "${var.prefix}-airflow-dag-processor-${var.airflow_dag_processors[count.index].name}"
  container_definitions = jsonencode([
    {
      "command" = ["/home/vcap/app/dataflow/bin/aws-dag-processor.sh"],
      "environment" = [
        {
          "name"  = "DB_HOST",
          "value" = local.airflow_dag_processor_container_vars[count.index].db_host
        },
        {
          "name"  = "DB_NAME",
          "value" = local.airflow_dag_processor_container_vars[count.index].db_name
        },
        {
          "name"  = "DB_PASSWORD",
          "value" = local.airflow_dag_processor_container_vars[count.index].db_password
        },
        {
          "name"  = "DB_PORT",
          "value" = tostring(local.airflow_dag_processor_container_vars[count.index].db_port)
        },
        {
          "name"  = "DB_USER",
          "value" = local.airflow_dag_processor_container_vars[count.index].db_user
        },
        {
          "name"  = "SECRET_KEY",
          "value" = local.airflow_dag_processor_container_vars[count.index].secret_key
        },
        {
          "name"  = "SENTRY_ENVIRONMENT",
          "value" = local.airflow_dag_processor_container_vars[count.index].sentry_environment
        },
        {
          "name"  = "AIRFLOW__LOGGING__REMOTE_BASE_LOG_FOLDER",
          "value" = "cloudwatch://${local.airflow_dag_processor_container_vars[count.index].cloudwatch_log_group_arn}"
        },
        {
          "name"  = "TEAM",
          "value" = local.airflow_dag_processor_container_vars[count.index].team
        },
        {
          # The key is already json-encoded, so to avoid it being double-json encoded, we decode it
          # first. But to do this we need to wrap it in double quotes so it's valid JSON.
          "name"  = "DAG_SYNC_GITHUB_KEY",
          "value" = jsondecode("\"${local.airflow_dag_processor_container_vars[count.index].dag_sync_github_key}\"")
        },
        {
          "name"  = "TEAM_SECRET_ID",
          "value" = local.airflow_dag_processor_container_vars[count.index].team_secret_id
        }
      ],
      "essential" = true,
      "image"     = local.airflow_dag_processor_container_vars[count.index].container_image,
      "logConfiguration" = {
        "logDriver" = "awslogs",
        "options" = {
          "awslogs-group"         = local.airflow_dag_processor_container_vars[count.index].log_group,
          "awslogs-region"        = local.airflow_dag_processor_container_vars[count.index].log_region,
          "awslogs-stream-prefix" = local.airflow_dag_processor_container_vars[count.index].container_name,
        }
      },
      "networkMode"       = "awsvpc",
      "memoryReservation" = local.airflow_dag_processor_container_vars[count.index].memory,
      "cpu"               = local.airflow_dag_processor_container_vars[count.index].cpu,
      "mountPoints"       = [],
      "name"              = local.airflow_dag_processor_container_vars[count.index].container_name,
      "portMappings" = [
        {
          "containerPort" = 8080,
          "hostPort"      = 8080,
          "protocol"      = "tcp"
        }
      ]
    }
  ])

  execution_role_arn       = aws_iam_role.airflow_dag_processor_execution[count.index].arn
  task_role_arn            = aws_iam_role.airflow_team[count.index].arn
  network_mode             = "awsvpc"
  cpu                      = local.airflow_container_cpu
  memory                   = local.airflow_container_memory
  requires_compatibilities = ["FARGATE"]

  lifecycle {
    ignore_changes = [revision]
  }
}

resource "aws_cloudwatch_log_group" "airflow_dag_processor" {
  count             = var.airflow_on ? length(var.airflow_dag_processors) : 0
  name              = "${var.prefix}-airflow-dag-processor-${var.airflow_dag_processors[count.index].name}"
  retention_in_days = "3653"
}

resource "aws_cloudwatch_log_subscription_filter" "airflow_dag_processor" {
  count           = var.cloudwatch_subscription_filter && var.airflow_on ? length(var.airflow_dag_processors) : 0
  name            = "${var.prefix}-airflow-dag-processor-${var.airflow_dag_processors[count.index].name}"
  log_group_name  = aws_cloudwatch_log_group.airflow_dag_processor[count.index].name
  filter_pattern  = ""
  destination_arn = var.cloudwatch_destination_arn
}

resource "aws_cloudwatch_log_group" "airflow" {
  count             = var.airflow_on ? 1 : 0
  name              = "${var.prefix}-airflow"
  retention_in_days = "3653"
}

resource "aws_iam_role" "airflow_dag_processor_execution" {
  count              = var.airflow_on ? length(var.airflow_dag_processors) : 0
  name               = "${var.prefix}-airflow-dag-processor-${var.airflow_dag_processors[count.index].name}"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.airflow_dag_processor_execution_ecs_tasks_assume_role[count.index].json
}

data "aws_iam_policy_document" "airflow_dag_processor_execution_ecs_tasks_assume_role" {
  count = var.airflow_on ? length(var.airflow_dag_processors) : 0
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "airflow_dag_processor_execution" {
  count      = var.airflow_on ? length(var.airflow_dag_processors) : 0
  role       = aws_iam_role.airflow_dag_processor_execution[count.index].name
  policy_arn = aws_iam_policy.airflow_dag_processor_execution[count.index].arn
}

resource "aws_iam_policy" "airflow_dag_processor_execution" {
  count  = var.airflow_on ? length(var.airflow_dag_processors) : 0
  name   = "${var.prefix}-airflow-dag-processor-${var.airflow_dag_processors[count.index].name}"
  path   = "/"
  policy = data.aws_iam_policy_document.airflow_dag_processor_execution[count.index].json
}

data "aws_iam_policy_document" "airflow_dag_processor_execution" {
  count = var.airflow_on ? length(var.airflow_dag_processors) : 0
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "${aws_cloudwatch_log_group.airflow_dag_processor[count.index].arn}:*",
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

data "aws_iam_policy_document" "airflow_dag_processor_task_ecs_tasks_assume_role" {
  count = var.airflow_on ? length(var.airflow_dag_processors) : 0
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

module "airflow_outgoing_matchbox_api" {
  count  = var.matchbox_on && var.airflow_on ? 1 : 0
  source = "./modules/security_group_client_server_connections"

  client_security_groups = [aws_security_group.airflow_dag_processor_service]
  server_security_groups = [aws_security_group.matchbox_service[count.index]]
  ports                  = [local.matchbox_api_port]

  depends_on = [aws_vpc_peering_connection.matchbox_to_main[0]]
}
