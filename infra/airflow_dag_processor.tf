resource "aws_ecs_service" "airflow_dag_processor" {
  count                      = var.airflow_on ? length(var.airflow_dag_processors) : 0
  name                       = "${var.prefix}-airflow-dag-processor-${var.airflow_dag_processors[count.index]}"
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
      cpu             = "${local.airflow_container_cpu}"
      memory          = "${local.airflow_container_memory}"

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

      team                = "${v}"
      dag_sync_github_key = "${var.dag_sync_github_key}"
    }
  ]
}

resource "aws_ecs_task_definition" "airflow_dag_processor_service" {
  count  = var.airflow_on ? length(var.airflow_dag_processors) : 0
  family = "${var.prefix}-airflow-dag-processor-${var.airflow_dag_processors[count.index]}"
  container_definitions = templatefile(
    "${path.module}/airflow_dag_processor_container_definitions.json",
    local.airflow_dag_processor_container_vars[count.index]
  )
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
  name              = "${var.prefix}-airflow-dag-processor-${var.airflow_dag_processors[count.index]}"
  retention_in_days = "3653"
}

resource "aws_cloudwatch_log_subscription_filter" "airflow_dag_processor" {
  count           = var.cloudwatch_subscription_filter && var.airflow_on ? length(var.airflow_dag_processors) : 0
  name            = "${var.prefix}-airflow-dag-processor-${var.airflow_dag_processors[count.index]}"
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
  name               = "${var.prefix}-airflow-dag-processor-${var.airflow_dag_processors[count.index]}"
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
  name   = "${var.prefix}-airflow-dag-processor-${var.airflow_dag_processors[count.index]}"
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

resource "aws_iam_role" "airflow_team" {
  count              = var.airflow_on ? length(var.airflow_dag_processors) : 0
  name               = "${local.airflow_team_role_prefix}${var.airflow_dag_processors[count.index]}"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.airflow_dag_processor_task_ecs_tasks_assume_role[count.index].json
}

resource "aws_iam_policy" "airflow_team" {
  count  = var.airflow_on ? length(var.airflow_dag_processors) : 0
  name   = "${local.airflow_team_role_prefix}${var.airflow_dag_processors[count.index]}"
  path   = "/"
  policy = data.aws_iam_policy_document.airflow_team[count.index].json
}

resource "aws_iam_role_policy_attachment" "airflow_team" {
  count      = var.airflow_on ? length(var.airflow_dag_processors) : 0
  role       = aws_iam_role.airflow_team[count.index].name
  policy_arn = aws_iam_policy.airflow_team[count.index].arn
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

data "aws_iam_policy_document" "airflow_team" {
  count = var.airflow_on ? length(var.airflow_dag_processors) : 0
  statement {
    actions = [
      "logs:CreateLogGroup"
    ]

    # Should be tighter
    resources = [
      "*"
    ]
  }

  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    # Should be tighter
    resources = [
      "*"
    ]
  }
}
