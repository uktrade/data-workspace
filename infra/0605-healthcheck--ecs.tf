resource "aws_ecs_service" "healthcheck" {
  name                       = "${var.prefix}-healthcheck"
  cluster                    = aws_ecs_cluster.main_cluster.id
  task_definition            = aws_ecs_task_definition.healthcheck.arn
  desired_count              = 1
  launch_type                = "FARGATE"
  platform_version           = "1.4.0"
  deployment_maximum_percent = 600

  network_configuration {
    subnets         = aws_subnet.private_with_egress.*.id
    security_groups = ["${aws_security_group.healthcheck_service.id}"]
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.healthcheck.arn
    container_port   = local.healthcheck_container_port
    container_name   = local.healthcheck_container_name
  }

  service_registries {
    registry_arn = aws_service_discovery_service.healthcheck.arn
  }

  depends_on = [
    # The target group must have been associated with the listener first
    aws_alb_listener.healthcheck,
  ]
}

data "external" "healthcheck_current_tag" {
  program = ["${path.module}/container-tag.sh"]

  query = {
    cluster_name   = "${aws_ecs_cluster.main_cluster.name}"
    service_name   = "${var.prefix}-healthcheck" # Manually specified to avoid a cycle
    container_name = "healthcheck"
  }
}

resource "aws_service_discovery_service" "healthcheck" {
  name = "${var.prefix}-healthcheck"
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.jupyterhub.id
    dns_records {
      ttl  = 10
      type = "A"
    }
  }

  # Needed for a service to be able to register instances with a target group,
  # but only if it has a service_registries, which we do
  # https://forums.aws.amazon.com/thread.jspa?messageID=852407&tstart=0
  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_ecs_task_definition" "healthcheck" {
  family = "${var.prefix}-healthcheck"
  container_definitions = jsonencode([
    {
      "name"              = local.healthcheck_container_name,
      "image"             = "${aws_ecr_repository.healthcheck.repository_url}:${data.external.healthcheck_current_tag.result.tag}",
      "memoryReservation" = local.healthcheck_container_memory,
      "cpu"               = local.healthcheck_container_cpu,
      "essential"         = true,
      "portMappings" = [{
        "containerPort" = local.healthcheck_container_port
      }],
      "logConfiguration" = {
        "logDriver" = "awslogs",
        "options" = {
          "awslogs-group"         = aws_cloudwatch_log_group.healthcheck.name,
          "awslogs-region"        = data.aws_region.aws_region.name,
          "awslogs-stream-prefix" = local.healthcheck_container_name
        }
      },
      "environment" = [{
        "name"  = "PORT",
        "value" = tostring(local.healthcheck_container_port)
        }, {
        "name"  = "URL",
        "value" = "https://${var.admin_domain}/healthcheck"
      }]
    }
    ]
  )

  execution_role_arn       = aws_iam_role.healthcheck_task_execution.arn
  task_role_arn            = aws_iam_role.healthcheck_task.arn
  network_mode             = "awsvpc"
  cpu                      = local.healthcheck_container_cpu
  memory                   = local.healthcheck_container_memory
  requires_compatibilities = ["FARGATE"]

  lifecycle {
    ignore_changes = [
      revision,
    ]
  }
}

resource "aws_cloudwatch_log_group" "healthcheck" {
  name              = "${var.prefix}-healthcheck"
  retention_in_days = "3653"
}

resource "aws_cloudwatch_log_subscription_filter" "healthcheck" {
  count           = var.cloudwatch_subscription_filter ? 1 : 0
  name            = "${var.prefix}-healthcheck"
  log_group_name  = aws_cloudwatch_log_group.healthcheck.name
  filter_pattern  = ""
  destination_arn = var.cloudwatch_destination_arn
}

resource "aws_iam_role" "healthcheck_task_execution" {
  name               = "${var.prefix}-healthcheck-task-execution"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.healthcheck_task_execution_ecs_tasks_assume_role.json
}

data "aws_iam_policy_document" "healthcheck_task_execution_ecs_tasks_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "healthcheck_task_execution" {
  role       = aws_iam_role.healthcheck_task_execution.name
  policy_arn = aws_iam_policy.healthcheck_task_execution.arn
}

resource "aws_iam_policy" "healthcheck_task_execution" {
  name   = "${var.prefix}-healthcheck-task-execution"
  path   = "/"
  policy = data.aws_iam_policy_document.healthcheck_task_execution.json
}

data "aws_iam_policy_document" "healthcheck_task_execution" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "${aws_cloudwatch_log_group.healthcheck.arn}:*",
    ]
  }

  statement {
    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]

    resources = [
      "${aws_ecr_repository.healthcheck.arn}",
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

resource "aws_iam_role" "healthcheck_task" {
  name               = "${var.prefix}-healthcheck-task"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.healthcheck_task_ecs_tasks_assume_role.json
}

data "aws_iam_policy_document" "healthcheck_task_ecs_tasks_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}
