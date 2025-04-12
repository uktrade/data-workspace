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
  container_definitions = templatefile(
    "${path.module}/ecs_notebooks_notebook_container_definitions.json", {
      container_image = "${aws_ecr_repository.tools[count.index].repository_url}:master"
      container_name  = "${local.notebook_container_name}"

      log_group  = "${aws_cloudwatch_log_group.notebook.name}"
      log_region = "${data.aws_region.aws_region.name}"

      sentry_dsn         = "${var.sentry_notebooks_dsn}"
      sentry_environment = "${var.sentry_environment}"

      metrics_container_image = "${aws_ecr_repository.metrics.repository_url}:master"
      s3sync_container_image  = "${aws_ecr_repository.s3sync.repository_url}:master"

      cloudwatch_namespace = "${var.cloudwatch_namespace}"
      cloudwatch_region    = "${var.cloudwatch_region}"

      home_directory = "/home/coder"
    }
  )
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
