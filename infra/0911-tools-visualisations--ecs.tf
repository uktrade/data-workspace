resource "aws_ecs_task_definition" "user_provided" {
  family = "${var.prefix}-user-provided"
  container_definitions = jsonencode([
    {
      "name"              = local.user_provided_container_name,
      "image"             = aws_ecr_repository.user_provided.repository_url,
      "memoryReservation" = local.user_provided_container_memory - 50,
      "cpu"               = local.user_provided_container_cpu - 5,
      "essential"         = true,
      "ulimits" = [
        {
          "softLimit" = 4096,
          "hardLimit" = 4096,
          "name"      = "nofile"
        }
      ],
      "logConfiguration" = {
        "logDriver" = "awslogs",
        "options" = {
          "awslogs-group"         = aws_cloudwatch_log_group.notebook.name,
          "awslogs-region"        = data.aws_region.aws_region.name,
          "awslogs-stream-prefix" = local.user_provided_container_name
        }
      },
      "environment" = []
    },
    {
      "name"              = "metrics",
      "image"             = "${aws_ecr_repository.metrics.repository_url}:master",
      "memoryReservation" = 50,
      "cpu"               = 5,
      "essential"         = true,
      "logConfiguration" = {
        "logDriver" = "awslogs",
        "options" = {
          "awslogs-group"         = aws_cloudwatch_log_group.notebook.name,
          "awslogs-region"        = data.aws_region.aws_region.name,
          "awslogs-stream-prefix" = "metrics"
        }
      },
      "environment" = [
        {
          "name"  = "PORT",
          "value" = "8889"
        },
      ]
    }
  ])

  execution_role_arn       = aws_iam_role.notebook_task_execution.arn
  network_mode             = "awsvpc"
  cpu                      = local.user_provided_container_cpu
  memory                   = local.user_provided_container_memory
  requires_compatibilities = ["FARGATE"]

  lifecycle {
    ignore_changes = [
      revision,
    ]
  }
}

data "aws_iam_policy_document" "user_provided_access_template" {
  statement {
    resources = ["*"]
    actions   = ["*"]
    effect    = "Deny"
  }
}
