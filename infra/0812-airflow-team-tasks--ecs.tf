resource "aws_ecs_cluster" "airflow_dag_tasks" {
  name = "${var.prefix}-airflow-dag-tasks"
}

resource "aws_ecs_task_definition" "airflow_dag_tasks" {
  count  = var.airflow_on ? 1 : 0
  family = "${var.prefix}-airflow-dag-tasks"
  container_definitions = jsonencode([
    {
      "environment" = [
        {
          "name"  = "DB_HOST",
          "value" = aws_rds_cluster.airflow[count.index].endpoint,
        },
        {
          "name"  = "DB_NAME",
          "value" = aws_rds_cluster.airflow[count.index].database_name,
        },
        {
          "name"  = "DB_PASSWORD",
          "value" = random_string.aws_db_instance_airflow_password.result,
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
          "name"  = "SENTRY_ENVIRONMENT",
          "value" = var.sentry_environment
        },
        {
          "name"  = "AIRFLOW__LOGGING__REMOTE_BASE_LOG_FOLDER",
          "value" = "cloudwatch://${aws_cloudwatch_log_group.airflow_dag_tasks_airflow_logging[0].arn}"
        },
        {
          # The key is already json-encoded, so to avoid it being double-json encoded, we decode it
          # first. But to do this we need to wrap it in double quotes so it's valid JSON.
          "name"  = "DAG_SYNC_GITHUB_KEY",
          "value" = jsondecode("\"${local.airflow_dag_processor_container_vars[count.index].dag_sync_github_key}\"")
        },
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
      "networkMode" = "awsvpc",
      "mountPoints" = [],
      "name"        = "airflow",
      "portMappings" = [
        {
          "containerPort" = 8080,
          "hostPort"      = 8080,
          "protocol"      = "tcp"
        }
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

resource "aws_cloudwatch_log_group" "airflow_dag_tasks" {
  count             = var.airflow_on ? 1 : 0
  name              = "${var.prefix}-airflow-dag-tasks"
  retention_in_days = "3653"
}

resource "aws_cloudwatch_log_group" "airflow_dag_tasks_airflow_logging" {
  count             = var.airflow_on ? 1 : 0
  name              = "${var.prefix}-airflow-dag-tasks-airflow-logging"
  retention_in_days = "3653"
}
