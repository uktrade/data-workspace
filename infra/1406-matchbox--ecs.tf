
locals {
  matchbox_container_vars = [for i, v in var.matchbox_instances : {
    container_image          = "${aws_ecr_repository.matchbox[0].repository_url}:master"
    container_name           = "matchbox"
    cpu                      = "${local.matchbox_container_cpu}"
    memory                   = "${local.matchbox_container_memory}"
    database_uri             = "postgresql://${aws_rds_cluster.matchbox[i].master_username}:${random_string.aws_db_instance_matchbox_password[i].result}@${aws_rds_cluster.matchbox[i].endpoint}:5432/${aws_rds_cluster.matchbox[i].database_name}"
    matchbox_s3_cache        = "${var.matchbox_s3_cache}-${var.matchbox_instances[i]}"
    log_group                = "${aws_cloudwatch_log_group.matchbox[0].name}"
    log_region               = "${data.aws_region.aws_region.name}"
    mb__postgres__host       = "${aws_rds_cluster.matchbox[i].endpoint}"
    mb__postgres__user       = "${aws_rds_cluster.matchbox[i].master_username}"
    mb__postgres__password   = "${random_string.aws_db_instance_matchbox_password[i].result}"
    mb__postgres__database   = "${aws_rds_cluster.matchbox[i].database_name}"
    mb__api__api_key         = "${var.matchbox_api_key}"
    sentry_matchbox_dsn      = "${var.sentry_matchbox_dsn}"
    matchbox_datadog_api_key = "${var.matchbox_datadog_api_key}"
    datadog_container_image  = "${aws_ecr_repository.datadog.repository_url}:7"

    matchbox_datadog_environment = "${var.matchbox_datadog_environment}"
  }]
}

resource "aws_ecs_cluster" "matchbox" {
  name = "${var.prefix}-matchbox"
}

resource "aws_ecs_service" "matchbox" {
  count                             = var.matchbox_on ? length(var.matchbox_instances) : 0
  name                              = "${var.prefix}-matchbox-${var.matchbox_instances[count.index]}"
  cluster                           = aws_ecs_cluster.matchbox.id
  task_definition                   = aws_ecs_task_definition.matchbox_service[count.index].arn
  desired_count                     = 1
  launch_type                       = "FARGATE"
  deployment_maximum_percent        = 200
  platform_version                  = "1.4.0"
  health_check_grace_period_seconds = "10"

  service_registries {
    registry_arn = aws_service_discovery_service.matchbox[0].arn
  }

  network_configuration {
    subnets         = ["${aws_subnet.matchbox_private.*.id[0]}"]
    security_groups = ["${aws_security_group.matchbox_service[count.index].id}"]
  }
}

resource "aws_service_discovery_service" "matchbox" {
  count = var.matchbox_on ? length(var.matchbox_instances) : 0
  name  = "matchbox"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.jupyterhub.id
    dns_records {
      ttl  = 10
      type = "A"
    }
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_ecs_task_definition" "matchbox_service" {
  count  = var.matchbox_on ? length(var.matchbox_instances) : 0
  family = "${var.prefix}-matchbox-${var.matchbox_instances[count.index]}"
  container_definitions = templatefile(
    "${path.module}/ecs_matchbox_matchbox_container_definitions.json",
    local.matchbox_container_vars[count.index]
  )
  execution_role_arn = aws_iam_role.matchbox_task_execution[count.index].arn
  task_role_arn      = aws_iam_role.matchbox_task[count.index].arn
  network_mode       = "awsvpc"

  cpu                      = local.matchbox_container_cpu
  memory                   = local.matchbox_container_memory
  requires_compatibilities = ["FARGATE"]
  tags                     = {}

  lifecycle {
    ignore_changes = [
      revision,
    ]
  }
}

resource "aws_iam_role" "matchbox_task_execution" {
  count              = var.matchbox_on ? length(var.matchbox_instances) : 0
  name               = "${var.prefix}-matchbox-task-execution-${var.matchbox_instances[count.index]}"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.matchbox_task_execution_ecs_tasks_assume_role[count.index].json
}

data "aws_iam_policy_document" "matchbox_task_execution_ecs_tasks_assume_role" {
  count = var.matchbox_on ? length(var.matchbox_instances) : 0
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "matchbox_task_execution" {
  count      = var.matchbox_on ? length(var.matchbox_instances) : 0
  role       = aws_iam_role.matchbox_task_execution[count.index].name
  policy_arn = aws_iam_policy.matchbox_task_execution[count.index].arn
}

resource "aws_iam_policy" "matchbox_task_execution" {
  count  = var.matchbox_on ? length(var.matchbox_instances) : 0
  name   = "${var.prefix}-matchbox-${var.matchbox_instances[count.index]}-task-execution"
  path   = "/"
  policy = data.aws_iam_policy_document.matchbox_task_execution[count.index].json
}

data "aws_iam_policy_document" "matchbox_task_execution" {
  count = var.matchbox_on ? length(var.matchbox_instances) : 0

  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "${aws_cloudwatch_log_group.matchbox[0].arn}:*",
    ]
  }

  statement {
    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]

    resources = [
      "${aws_ecr_repository.matchbox[0].arn}",
      "${aws_ecr_repository.datadog.arn}",
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

resource "aws_iam_role" "matchbox_task" {
  count              = var.matchbox_on ? length(var.matchbox_instances) : 0
  name               = "${var.prefix}-matchbox-${var.matchbox_instances[count.index]}-task"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.matchbox_task_ecs_tasks_assume_role[count.index].json
}

data "aws_iam_policy_document" "matchbox_task_ecs_tasks_assume_role" {
  count = var.matchbox_on ? length(var.matchbox_instances) : 0
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "matchbox_task" {
  count      = var.matchbox_on ? length(var.matchbox_instances) : 0
  role       = aws_iam_role.matchbox_task[count.index].name
  policy_arn = aws_iam_policy.matchbox_task[count.index].arn
}

resource "aws_iam_policy" "matchbox_task" {
  count  = var.matchbox_on ? length(var.matchbox_instances) : 0
  name   = "${var.prefix}-matchbox-${var.matchbox_instances[count.index]}-task"
  path   = "/"
  policy = data.aws_iam_policy_document.matchbox_task[count.index].json
}

data "aws_iam_policy_document" "matchbox_task" {
  count = var.matchbox_on ? length(var.matchbox_instances) : 0

  statement {
    actions = [
      "s3:*",
    ]

    resources = ["arn:aws:s3:::${aws_s3_bucket.matchbox_s3_cache[count.index].id}", "arn:aws:s3:::${aws_s3_bucket.matchbox_s3_cache[count.index].id}/*"]
  }
}

resource "aws_cloudwatch_log_group" "matchbox" {
  count             = var.matchbox_on ? 1 : 0
  name              = "${var.prefix}-matchbox"
  retention_in_days = "3653"
}

resource "aws_cloudwatch_log_subscription_filter" "matchbox" {
  count           = var.cloudwatch_subscription_filter && var.matchbox_on ? 1 : 0
  name            = "${var.prefix}-matchbox"
  log_group_name  = aws_cloudwatch_log_group.matchbox[count.index].name
  filter_pattern  = ""
  destination_arn = var.cloudwatch_destination_arn
}

resource "aws_cloudwatch_log_subscription_filter" "matchbox_datadog" {
  count           = var.cloudwatch_destination_datadog_arn != "" && var.matchbox_on ? 1 : 0
  name            = "${var.prefix}-matchbox-datadog"
  log_group_name  = aws_cloudwatch_log_group.matchbox[count.index].name
  filter_pattern  = ""
  destination_arn = var.cloudwatch_destination_datadog_arn
  role_arn        = aws_iam_role.matchbox_datadog_logs[0].arn
}

resource "aws_cloudwatch_log_subscription_filter" "matchbox_datadog_codebuild" {
  count           = var.cloudwatch_destination_datadog_arn != "" && var.matchbox_on ? 1 : 0
  name            = "${var.prefix}-matchbox-codebuild-datadog"
  log_group_name  = aws_cloudwatch_log_group.matchbox_codebuild[count.index].name
  filter_pattern  = ""
  destination_arn = var.cloudwatch_destination_datadog_arn
  role_arn        = aws_iam_role.matchbox_datadog_logs[0].arn
}

resource "aws_iam_role" "matchbox_datadog_logs" {
  count = var.cloudwatch_destination_datadog_arn != "" && var.matchbox_on ? length(var.matchbox_instances) : 0
  name  = "${var.prefix}-matchbox-datadog-logs"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "logs.eu-west-2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "matchbox_datadog_logs" {
  count = var.cloudwatch_destination_datadog_arn != "" && var.matchbox_on ? length(var.matchbox_instances) : 0
  name  = "${var.prefix}-matchbox-datadog-logs"
  role  = aws_iam_role.matchbox_datadog_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      "Effect" = "Allow",
      "Action" = [
        "firehose:PutRecord",
        "firehose:PutRecordBatch",
        "kinesis:PutRecord",
        "kinesis:PutRecords"
      ],
      "Resource" = var.cloudwatch_destination_datadog_arn
    }]
  })
}
