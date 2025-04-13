resource "aws_ecs_cluster" "notebooks" {
  name = "${var.prefix}-notebooks"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_task_definition" "tools" {
  count  = length(var.tools)
  family = "${var.prefix}-${var.tools[count.index].name}"
  container_definitions = jsonencode([
    {
      "name"      = local.notebook_container_name,
      "image"     = "${aws_ecr_repository.tools[count.index].repository_url}:master",
      "essential" = true,
      "ulimits" = [{
        "softLimit" = 4096,
        "hardLimit" = 4096,
        "name"      = "nofile"
      }],
      "logConfiguration" = {
        "logDriver" = "awslogs",
        "options" = {
          "awslogs-group"         = aws_cloudwatch_log_group.notebook.name,
          "awslogs-region"        = data.aws_region.aws_region.name,
          "awslogs-stream-prefix" = local.notebook_container_name
        }
      },
      "environment" = [{
        "name"  = "SENTRY_DSN",
        "value" = var.sentry_notebooks_dsn
        }, {
        "name"  = "SENTRY_ENVIRONMENT",
        "value" = var.sentry_environment
      }],
      "mountPoints" = [{
        "sourceVolume"  = "home_directory",
        "containerPath" = "/home/coder"
        }, {
        "sourceVolume"  = "home_directory",
        "containerPath" = "/home/dw-user"
      }]
    },
    {
      "name"      = "metrics",
      "image"     = "${aws_ecr_repository.metrics.repository_url}:master",
      "essential" = true,
      "logConfiguration" = {
        "logDriver" = "awslogs",
        "options" = {
          "awslogs-group"         = aws_cloudwatch_log_group.notebook.name,
          "awslogs-region"        = data.aws_region.aws_region.name,
          "awslogs-stream-prefix" = "metrics"
        }
      },
      "environment" = [{
        "name"  = "PORT",
        "value" = "8889"
      }]
    },
    {
      "name"      = "s3sync",
      "image"     = "${aws_ecr_repository.s3sync.repository_url}:master",
      "essential" = true,
      "logConfiguration" = {
        "logDriver" = "awslogs",
        "options" = {
          "awslogs-group"         = aws_cloudwatch_log_group.notebook.name
          "awslogs-region"        = data.aws_region.aws_region.name,
          "awslogs-stream-prefix" = "s3sync"
        }
      },
      "mountPoints" = [{
        "sourceVolume"  = "home_directory",
        "containerPath" = "/home/s3sync/data"
      }],
      "environment" = [{
        "name"  = "SENTRY_DSN",
        "value" = var.sentry_notebooks_dsn
        }, {
        "name"  = "SENTRY_ENVIRONMENT",
        "value" = var.sentry_environment
        }, {
        "name"  = "CLOUDWATCH_MONITORING_NAMESPACE",
        "value" = "${var.cloudwatch_namespace}/S3Sync"
        }, {
        "name"  = "CLOUDWATCH_MONITORING_REGION",
        "value" = "${var.cloudwatch_region}"
      }]
    }
  ])

  execution_role_arn       = aws_iam_role.notebook_task_execution.arn
  network_mode             = "awsvpc"
  cpu                      = local.notebook_container_cpu
  memory                   = local.notebook_container_memory
  requires_compatibilities = ["FARGATE"]

  ephemeral_storage {
    size_in_gib = 50
  }

  volume {
    name = "home_directory"
  }

  lifecycle {
    ignore_changes = [
      revision,
    ]
  }
}
