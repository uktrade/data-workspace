resource "aws_ecs_service" "airflow_scheduler" {
  count                      = var.airflow_on ? 1 : 0
  name                       = "${var.prefix}-airflow-scheduler"
  cluster                    = aws_ecs_cluster.main_cluster.id
  task_definition            = aws_ecs_task_definition.airflow_scheduler[count.index].arn
  desired_count              = 1
  launch_type                = "FARGATE"
  deployment_maximum_percent = 200
  platform_version           = "1.4.0"

  network_configuration {
    subnets         = ["${aws_subnet.private_with_egress.*.id[0]}"]
    security_groups = ["${aws_security_group.airflow_scheduler.id}"]
  }
}

resource "aws_ecs_task_definition" "airflow_scheduler" {
  count  = var.airflow_on ? 1 : 0
  family = "${var.prefix}-airflow-scheduler"
  container_definitions = jsonencode([
    {
      "command"    = ["/home/vcap/app/dataflow/bin/airflow-scheduler.sh"]
      "entryPoint" = ["/home/vcap/app/dataflow/bin/aws-wrapper-no-git-sync.sh"],
      "environment" = [
        {
          "name"  = "DB_HOST",
          "value" = aws_rds_cluster.airflow[count.index].endpoint
        },
        {
          "name"  = "DB_NAME",
          "value" = aws_rds_cluster.airflow[count.index].database_name
        },
        {
          "name"  = "DB_PASSWORD",
          "value" = random_string.aws_db_instance_airflow_password.result,
        },
        {
          "name"  = "DB_PORT",
          "value" = tostring(aws_rds_cluster.airflow[count.index].port),
        },
        {
          "name"  = "DB_USER",
          "value" = aws_rds_cluster.airflow[count.index].master_username
        },
        {
          "name"  = "SECRET_KEY",
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
          "value" = aws_security_group.airflow_dag_processor_service.id
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
          "name"  = "CUSTOM_ECS_EXECUTOR__TASK_ROLE_ARN_PREFIX",
          "value" = "arn:aws:iam::${data.aws_caller_identity.aws_caller_identity.account_id}:role/${local.airflow_team_role_prefix}"
        },
        {
          "name"  = "PREFIX",
          "value" = var.prefix
        }
      ],
      "essential" = true,
      "image"     = "${aws_ecr_repository.airflow.repository_url}:master"
      "logConfiguration" = {
        "logDriver" = "awslogs",
        "options" = {
          "awslogs-group"         = "${aws_cloudwatch_log_group.airflow_scheduler[count.index].name}",
          "awslogs-region"        = "${data.aws_region.aws_region.name}",
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
        }
      ]
    }
  ])

  execution_role_arn       = aws_iam_role.airflow_scheduler_execution[count.index].arn
  task_role_arn            = aws_iam_role.airflow_scheduler_task[count.index].arn
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

resource "aws_cloudwatch_log_group" "airflow_scheduler" {
  count             = var.airflow_on ? 1 : 0
  name              = "${var.prefix}-airflow-scheduler"
  retention_in_days = "3653"
}

resource "aws_iam_role" "airflow_scheduler_execution" {
  count              = var.airflow_on ? 1 : 0
  name               = "${var.prefix}-airflow-scheduler-execution"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.airflow_scheduler_execution_ecs_tasks_assume_role[count.index].json
}

resource "aws_iam_policy" "airflow_scheduler_execution" {
  count  = var.airflow_on ? 1 : 0
  name   = "${var.prefix}-airflow-scheduler-execution"
  path   = "/"
  policy = data.aws_iam_policy_document.airflow_scheduler_execution[count.index].json
}

resource "aws_iam_role_policy_attachment" "airflow_scheduler_execution" {
  count      = var.airflow_on ? 1 : 0
  role       = aws_iam_role.airflow_scheduler_execution[count.index].name
  policy_arn = aws_iam_policy.airflow_scheduler_execution[count.index].arn
}

data "aws_iam_policy_document" "airflow_scheduler_execution" {
  count = var.airflow_on ? 1 : 0
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "${aws_cloudwatch_log_group.airflow_scheduler[count.index].arn}:*",
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

resource "aws_iam_role" "airflow_scheduler_task" {
  count              = var.airflow_on ? 1 : 0
  name               = "${var.prefix}-airflow-scheduler-task"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.airflow_scheduler_task_ecs_tasks_assume_role[count.index].json
}

resource "aws_iam_policy" "airflow_scheduler_task" {
  count  = var.airflow_on ? 1 : 0
  name   = "${var.prefix}-airflow-scheduler-task"
  path   = "/"
  policy = data.aws_iam_policy_document.airflow_scheduler_task[0].json
}

resource "aws_iam_role_policy_attachment" "airflow_scheduler_task" {
  count      = var.airflow_on ? 1 : 0
  role       = aws_iam_role.airflow_scheduler_task[count.index].name
  policy_arn = aws_iam_policy.airflow_scheduler_task[0].arn
}

data "aws_iam_policy_document" "airflow_scheduler_task" {
  count = var.airflow_on ? 1 : 0

  statement {
    actions = [
      "ecs:DescribeClusters"
    ]

    resources = [
      "arn:aws:ecs:${data.aws_region.aws_region.name}:${data.aws_caller_identity.aws_caller_identity.account_id}:cluster/${aws_ecs_cluster.airflow_dag_tasks.name}",
    ]
  }

  statement {
    actions = [
      "ecs:RunTask",
    ]

    condition {
      test     = "ArnEquals"
      variable = "ecs:cluster"
      values = [
        "arn:aws:ecs:${data.aws_region.aws_region.name}:${data.aws_caller_identity.aws_caller_identity.account_id}:cluster/${aws_ecs_cluster.airflow_dag_tasks.name}",
      ]
    }

    resources = [
      "arn:aws:ecs:${data.aws_region.aws_region.name}:${data.aws_caller_identity.aws_caller_identity.account_id}:task-definition/${aws_ecs_task_definition.airflow_dag_tasks[0].family}:*"
    ]
  }

  statement {
    actions = [
      "ecs:DescribeTasks",
    ]

    condition {
      test     = "ArnEquals"
      variable = "ecs:cluster"
      values = [
        "arn:aws:ecs:${data.aws_region.aws_region.name}:${data.aws_caller_identity.aws_caller_identity.account_id}:cluster/${aws_ecs_cluster.airflow_dag_tasks.name}",
      ]
    }

    resources = [
      "arn:aws:ecs:${data.aws_region.aws_region.name}:${data.aws_caller_identity.aws_caller_identity.account_id}:task/*",
    ]
  }

  statement {
    actions = [
      "ecs:StopTask",
    ]

    condition {
      test     = "ArnEquals"
      variable = "ecs:cluster"
      values = [
        "arn:aws:ecs:${data.aws_region.aws_region.name}:${data.aws_caller_identity.aws_caller_identity.account_id}:cluster/${aws_ecs_cluster.airflow_dag_tasks.name}",
      ]
    }

    resources = [
      "arn:aws:ecs:${data.aws_region.aws_region.name}:${data.aws_caller_identity.aws_caller_identity.account_id}:task/*",
    ]
  }

  statement {
    actions = [
      "iam:PassRole"
    ]
    resources = concat([
      "${aws_iam_role.airflow_webserver_execution[count.index].arn}",
    ], [for team_role in aws_iam_role.airflow_team : team_role.arn])
  }

  statement {
    actions = [
      "logs:CreateLogGroup"
    ]

    # Should be tighter
    resources = [
      "*"
    ]
  }
}

data "aws_iam_policy_document" "airflow_scheduler_execution_ecs_tasks_assume_role" {
  count = var.airflow_on != "" ? 1 : 0
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "airflow_scheduler_task_ecs_tasks_assume_role" {
  count = var.airflow_on != "" ? 1 : 0
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}
