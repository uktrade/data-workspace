resource "aws_ecs_service" "prometheus" {
  name             = "${var.prefix}-prometheus"
  cluster          = aws_ecs_cluster.main_cluster.id
  task_definition  = aws_ecs_task_definition.prometheus.arn
  desired_count    = 1
  launch_type      = "FARGATE"
  platform_version = "1.4.0"

  network_configuration {
    subnets         = aws_subnet.private_with_egress.*.id
    security_groups = ["${aws_security_group.prometheus_service.id}"]
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.prometheus.arn
    container_port   = local.prometheus_container_port
    container_name   = local.prometheus_container_name
  }

  service_registries {
    registry_arn = aws_service_discovery_service.prometheus.arn
  }

  depends_on = [
    # The target group must have been associated with the listener first
    aws_alb_listener.prometheus,
  ]
}

data "external" "prometheus_current_tag" {
  program = ["${path.module}/container-tag.sh"]

  query = {
    cluster_name   = "${aws_ecs_cluster.main_cluster.name}"
    service_name   = "${var.prefix}-prometheus" # Manually specified to avoid a cycle
    container_name = "${local.prometheus_container_name}"
  }
}

resource "aws_service_discovery_service" "prometheus" {
  name = "${var.prefix}-prometheus"
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

resource "aws_ecs_task_definition" "prometheus" {
  family = "${var.prefix}-prometheus"
  container_definitions = jsonencode([
    {
      "name"              = local.prometheus_container_name,
      "image"             = "${aws_ecr_repository.prometheus.repository_url}:${data.external.prometheus_current_tag.result.tag}",
      "memoryReservation" = local.prometheus_container_memory,
      "cpu"               = local.prometheus_container_cpu
      "essential"         = true,
      "portMappings" = [{
        "containerPort" = local.prometheus_container_port
      }],
      "logConfiguration" = {
        "logDriver" = "awslogs",
        "options" = {
          "awslogs-group"         = aws_cloudwatch_log_group.prometheus.name,
          "awslogs-region"        = data.aws_region.aws_region.name,
          "awslogs-stream-prefix" = local.prometheus_container_name,
        }
      },
      "environment" = [
        {
          "name"  = "URL",
          "value" = "https://${var.admin_domain}/api/v1/application"
        },
        {
          "name"  = "METRICS_SERVICE_DISCOVERY_BASIC_AUTH_USER",
          "value" = var.metrics_service_discovery_basic_auth_user
        },
        {
          "name"  = "METRICS_SERVICE_DISCOVERY_BASIC_AUTH_PASSWORD",
          "value" = var.metrics_service_discovery_basic_auth_password
      }]
    }
  ])

  execution_role_arn       = aws_iam_role.prometheus_task_execution.arn
  task_role_arn            = aws_iam_role.prometheus_task.arn
  network_mode             = "awsvpc"
  cpu                      = local.prometheus_container_cpu
  memory                   = local.prometheus_container_memory
  requires_compatibilities = ["FARGATE"]

  lifecycle {
    ignore_changes = [
      revision,
    ]
  }
}

resource "aws_cloudwatch_log_group" "prometheus" {
  name              = "${var.prefix}-prometheus"
  retention_in_days = "3653"
}

resource "aws_cloudwatch_log_subscription_filter" "prometheus" {
  count           = var.cloudwatch_subscription_filter ? 1 : 0
  name            = "${var.prefix}-prometheus"
  log_group_name  = aws_cloudwatch_log_group.prometheus.name
  filter_pattern  = ""
  destination_arn = var.cloudwatch_destination_arn
}

resource "aws_iam_role" "prometheus_task_execution" {
  name               = "${var.prefix}-prometheus-task-execution"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.prometheus_task_execution_ecs_tasks_assume_role.json
}

data "aws_iam_policy_document" "prometheus_task_execution_ecs_tasks_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "prometheus_task_execution" {
  role       = aws_iam_role.prometheus_task_execution.name
  policy_arn = aws_iam_policy.prometheus_task_execution.arn
}

resource "aws_iam_policy" "prometheus_task_execution" {
  name   = "${var.prefix}-prometheus-task-execution"
  path   = "/"
  policy = data.aws_iam_policy_document.prometheus_task_execution.json
}

data "aws_iam_policy_document" "prometheus_task_execution" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "${aws_cloudwatch_log_group.prometheus.arn}:*",
    ]
  }

  statement {
    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]

    resources = [
      "${aws_ecr_repository.prometheus.arn}",
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

resource "aws_iam_role" "prometheus_task" {
  name               = "${var.prefix}-prometheus-task"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.prometheus_task_ecs_tasks_assume_role.json
}

data "aws_iam_policy_document" "prometheus_task_ecs_tasks_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}
