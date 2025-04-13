resource "aws_ecs_task_definition" "mirrors_sync_cran_binary_rv4" {
  count  = var.mirrors_bucket_name != "" ? 1 : 0
  family = "jupyterhub-mirrors-sync-cran-binary-rv4"
  container_definitions = jsonencode([
    {
      "name"              = local.mirrors_sync_cran_binary_container_name,
      "image"             = "${aws_ecr_repository.mirrors_sync_cran_binary_rv4.repository_url}:master"
      "memoryReservation" = local.mirrors_sync_cran_binary_container_memory,
      "cpu"               = local.mirrors_sync_cran_binary_container_cpu,
      "essential"         = true,
      "portMappings"      = [],
      "logConfiguration" = {
        "logDriver" = "awslogs",
        "options" = {
          "awslogs-group"         = aws_cloudwatch_log_group.mirrors_sync.*.name[count.index],
          "awslogs-region"        = data.aws_region.aws_region.name,
          "awslogs-stream-prefix" = local.mirrors_sync_cran_binary_container_name
        }
      },
      "environment" = [
        {
          "name"  = "MIRRORS_BUCKET_NAME",
          "value" = var.mirrors_bucket_name,
        }
      ]
    }
  ])

  execution_role_arn       = aws_iam_role.mirrors_sync_task_execution.*.arn[count.index]
  task_role_arn            = aws_iam_role.mirrors_sync_task.*.arn[count.index]
  network_mode             = "awsvpc"
  cpu                      = local.mirrors_sync_container_cpu
  memory                   = local.mirrors_sync_container_memory
  requires_compatibilities = ["FARGATE"]
}

resource "aws_cloudwatch_log_group" "mirrors_sync" {
  count             = var.mirrors_bucket_name != "" ? 1 : 0
  name              = "jupyterhub-mirrors-sync"
  retention_in_days = "3653"
}

resource "aws_cloudwatch_log_subscription_filter" "mirrors_sync" {
  count           = var.mirrors_bucket_name != "" && var.cloudwatch_subscription_filter ? 1 : 0
  name            = "jupyterhub-mirrors-sync"
  log_group_name  = aws_cloudwatch_log_group.mirrors_sync.*.name[count.index]
  filter_pattern  = ""
  destination_arn = var.cloudwatch_destination_arn
}

resource "aws_iam_role" "mirrors_sync_task_execution" {
  count              = var.mirrors_bucket_name != "" ? 1 : 0
  name               = "mirrors-sync-task-execution"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.mirrors_sync_task_execution_ecs_tasks_assume_role.*.json[count.index]
}

data "aws_iam_policy_document" "mirrors_sync_task_execution_ecs_tasks_assume_role" {
  count = var.mirrors_bucket_name != "" ? 1 : 0
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "mirrors_sync_task_execution" {
  count      = var.mirrors_bucket_name != "" ? 1 : 0
  role       = aws_iam_role.mirrors_sync_task_execution.*.name[count.index]
  policy_arn = aws_iam_policy.mirrors_sync_task_execution.*.arn[count.index]
}

resource "aws_iam_policy" "mirrors_sync_task_execution" {
  count  = var.mirrors_bucket_name != "" ? 1 : 0
  name   = "jupyterhub-mirrors-sync-task-execution"
  path   = "/"
  policy = data.aws_iam_policy_document.mirrors_sync_task_execution.*.json[count.index]
}

data "aws_iam_policy_document" "mirrors_sync_task_execution" {
  count = var.mirrors_bucket_name != "" ? 1 : 0
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "${aws_cloudwatch_log_group.mirrors_sync.*.arn[count.index]}:*",
    ]
  }

  statement {
    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]

    resources = [
      "${aws_ecr_repository.mirrors_sync.arn}",
      "${aws_ecr_repository.mirrors_sync_cran_binary.arn}",
      "${aws_ecr_repository.mirrors_sync_cran_binary_rv4.arn}",
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

resource "aws_iam_role" "mirrors_sync_task" {
  count              = var.mirrors_bucket_name != "" ? 1 : 0
  name               = "jupyterhub-mirrors-sync-task"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.mirrors_sync_task_ecs_tasks_assume_role.*.json[count.index]
}

data "aws_iam_policy_document" "mirrors_sync_task_ecs_tasks_assume_role" {
  count = var.mirrors_bucket_name != "" ? 1 : 0
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "mirrors_sync" {
  count      = var.mirrors_bucket_name != "" ? 1 : 0
  role       = aws_iam_role.mirrors_sync_task.*.name[count.index]
  policy_arn = aws_iam_policy.mirrors_sync_task.*.arn[count.index]
}

resource "aws_iam_policy" "mirrors_sync_task" {
  count  = var.mirrors_bucket_name != "" ? 1 : 0
  name   = "jupyterhub-mirrors-sync-task"
  path   = "/"
  policy = data.aws_iam_policy_document.mirrors_sync_task.*.json[count.index]
}

data "aws_iam_policy_document" "mirrors_sync_task" {
  count = var.mirrors_bucket_name != "" ? 1 : 0
  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject"
    ]

    resources = [
      "${aws_s3_bucket.mirrors.*.arn[count.index]}/*",
    ]
  }
  statement {
    actions = [
      "s3:ListBucket",
    ]

    resources = [
      "${aws_s3_bucket.mirrors.*.arn[count.index]}",
    ]
  }
}
