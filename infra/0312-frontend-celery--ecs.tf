resource "aws_ecs_service" "admin_celery" {
  name                       = "${var.prefix}-admin-celery"
  cluster                    = aws_ecs_cluster.main_cluster.id
  task_definition            = aws_ecs_task_definition.admin_celery.arn
  desired_count              = 2
  launch_type                = "FARGATE"
  platform_version           = "1.4.0"
  deployment_maximum_percent = 600
  timeouts {}

  network_configuration {
    subnets         = aws_subnet.private_with_egress.*.id
    security_groups = ["${aws_security_group.admin_service.id}"]
  }
}

resource "aws_ecs_task_definition" "admin_celery" {
  family = "${var.prefix}-admin-celery"
  container_definitions = templatestring(
    local.admin_container_definitions,
    merge(local.admin_container_vars, tomap({ "container_command" = "[\"/dataworkspace/start-celery.sh\"]" }))
  )
  execution_role_arn       = aws_iam_role.admin_task_execution.arn
  task_role_arn            = aws_iam_role.admin_task.arn
  network_mode             = "awsvpc"
  cpu                      = local.celery_container_cpu
  memory                   = local.celery_container_memory
  requires_compatibilities = ["FARGATE"]

  lifecycle {
    ignore_changes = [
      revision,
    ]
  }
}

resource "aws_iam_role_policy_attachment" "celery_access_uploads_bucket" {
  role       = aws_iam_role.admin_task.name
  policy_arn = aws_iam_policy.celery_access_uploads_bucket.arn
}

resource "aws_iam_policy" "celery_access_uploads_bucket" {
  name   = "${var.prefix}-celery-access-uploads-bucket"
  path   = "/"
  policy = data.aws_iam_policy_document.celery_access_uploads_bucket.json
}

data "aws_iam_policy_document" "celery_access_uploads_bucket" {
  statement {
    actions = [
      "s3:ListBucket",
    ]

    resources = [
      "${aws_s3_bucket.uploads.arn}",
    ]
  }
}
