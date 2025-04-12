resource "aws_ecs_service" "arango" {
  count           = var.arango_on ? 1 : 0
  name            = "${var.prefix}-arango"
  cluster         = aws_ecs_cluster.main_cluster.id
  task_definition = aws_ecs_task_definition.arango_service[0].arn
  desired_count   = 1

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.arango_capacity_provider[0].name
    weight            = 100
    base              = 1
  }

  network_configuration {
    subnets         = [aws_subnet.datasets.*.id[0]]
    security_groups = [aws_security_group.arango_service[0].id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.arango[0].arn
    container_port   = "8529"
    container_name   = "arango"
  }

  service_registries {
    registry_arn = aws_service_discovery_service.arango[0].arn
  }

  depends_on = [
    # The target group must have been associated with the listener first
    aws_lb_listener.arango,
    aws_autoscaling_group.arango_service
  ]
}

resource "aws_service_discovery_service" "arango" {
  count = var.arango_on ? 1 : 0
  name  = "${var.prefix}-arango"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.jupyterhub.id
    dns_records {
      ttl  = 10
      type = "A"
    }
  }
}

resource "aws_ecs_task_definition" "arango_service" {
  count  = var.arango_on ? 1 : 0
  family = "${var.prefix}-arango"
  container_definitions = jsonencode([
    {
      "name"      = "arango",
      "image"     = "${aws_ecr_repository.arango[0].repository_url}:latest"
      "essential" = true,
      "portMappings" = [
        {
          "containerPort" = 8529,
          "protocol"      = "tcp"
        }
      ],
      "logConfiguration" = {
        "logDriver" = "awslogs",
        "options" = {
          "awslogs-group"         = "${aws_cloudwatch_log_group.arango[0].name}"
          "awslogs-region"        = "${data.aws_region.aws_region.name}"
          "awslogs-stream-prefix" = "arango"
        }
      },
      "environment" = [
        {
          "name"  = "ARANGO_ROOT_PASSWORD",
          "value" = "${random_string.aws_arangodb_root_password[0].result}"
        }
      ],
      "mountPoints" = [
        {
          "containerPath" = "/var/lib/arangodb3",
          "sourceVolume"  = "data-arango"
        }
      ]
    }
  ])

  execution_role_arn       = aws_iam_role.arango_task_execution[0].arn
  task_role_arn            = aws_iam_role.arango_task[0].arn
  network_mode             = "awsvpc"
  memory                   = var.arango_container_memory
  requires_compatibilities = ["EC2"]

  volume {
    name      = "data-arango"
    host_path = "/data/"
  }

  lifecycle {
    ignore_changes = [
      revision,
    ]
  }
}

resource "random_string" "aws_arangodb_root_password" {
  count   = var.arango_on ? 1 : 0
  length  = 64
  special = false

  lifecycle {
    ignore_changes = all
  }
}

resource "aws_ecs_capacity_provider" "arango_capacity_provider" {
  count = var.arango_on ? 1 : 0
  name  = "${var.prefix}-arango_service"
  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.arango_service[0].arn
    managed_scaling {
      maximum_scaling_step_size = 1000
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 3
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "arango" {
  count              = var.arango_on ? 1 : 0
  cluster_name       = aws_ecs_cluster.main_cluster.name
  capacity_providers = [aws_ecs_capacity_provider.arango_capacity_provider[0].name]
  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.arango_capacity_provider[0].name
  }
}

resource "aws_iam_role" "arango_task_execution" {
  count              = var.arango_on ? 1 : 0
  name               = "${var.prefix}-arango-task-execution"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.arango_task_execution_ecs_tasks_assume_role[0].json
}

data "aws_iam_policy_document" "arango_task_execution_ecs_tasks_assume_role" {
  count = var.arango_on ? 1 : 0
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "arango_task_execution" {
  count      = var.arango_on ? 1 : 0
  role       = aws_iam_role.arango_task_execution[0].name
  policy_arn = aws_iam_policy.arango_task_execution[0].arn
}

resource "aws_iam_policy" "arango_task_execution" {
  count  = var.arango_on ? 1 : 0
  name   = "${var.prefix}-arango-task-execution"
  path   = "/"
  policy = data.aws_iam_policy_document.arango_task_execution[0].json
}

data "aws_iam_policy_document" "arango_task_execution" {
  count = var.arango_on ? 1 : 0
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "${aws_cloudwatch_log_group.arango[0].arn}:*",
    ]
  }

  statement {
    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]

    resources = [
      "${aws_ecr_repository.arango[0].arn}",
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

resource "aws_iam_role" "arango_task" {
  count              = var.arango_on ? 1 : 0
  name               = "${var.prefix}-arango-task"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.arango_task_ecs_tasks_assume_role[0].json
}

data "aws_iam_policy_document" "arango_task_ecs_tasks_assume_role" {
  count = var.arango_on ? 1 : 0
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "arango_ecs" {
  count              = var.arango_on ? 1 : 0
  name               = "${var.prefix}-arango-ecs"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.arango_ecs_assume_role[0].json
}

resource "aws_iam_role_policy_attachment" "arango_ecs" {
  count      = var.arango_on ? 1 : 0
  role       = aws_iam_role.arango_ecs[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}

data "aws_iam_policy_document" "arango_ecs_assume_role" {
  count = var.arango_on ? 1 : 0
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}
