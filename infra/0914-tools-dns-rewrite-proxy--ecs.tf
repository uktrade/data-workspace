resource "aws_ecs_service" "dns_rewrite_proxy_new" {
  name             = "${var.prefix}-dns-rewrite-proxy-new"
  cluster          = aws_ecs_cluster.main_cluster.id
  task_definition  = aws_ecs_task_definition.dns_rewrite_proxy_new.arn
  desired_count    = 1
  launch_type      = "FARGATE"
  platform_version = "1.4.0"

  network_configuration {
    subnets         = ["${aws_subnet.private_with_egress.*.id[0]}"]
    security_groups = ["${aws_security_group.dns_rewrite_proxy.id}"]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.dns_rewrite_proxy_new.id
    container_name   = local.dns_rewrite_proxy_container_name
    container_port   = 53
  }
}

resource "aws_ecs_task_definition" "dns_rewrite_proxy_new" {
  family = "${var.prefix}-dns-rewrite-proxy-new"
  container_definitions = jsonencode(
    [
      {
        "name"              = local.dns_rewrite_proxy_container_name,
        "image"             = "${aws_ecr_repository.dns_rewrite_proxy.repository_url}:${data.external.dns_rewrite_proxy_current_tag.result.tag}",
        "memoryReservation" = local.dns_rewrite_proxy_container_memory,
        "cpu"               = local.dns_rewrite_proxy_container_cpu
        "essential"         = true,
        "portMappings" = [
          {
            "containerPort" = 53,
            "protocol"      = "udp"
          },
          {
            "containerPort" = 8888,
            "protocol"      = "tcp"
          },
        ],
        "logConfiguration" = {
          "logDriver" = "awslogs",
          "options" = {
            "awslogs-group"         = aws_cloudwatch_log_group.dns_rewrite_proxy.name,
            "awslogs-region"        = data.aws_region.aws_region.name,
            "awslogs-stream-prefix" = local.dns_rewrite_proxy_container_name,
          }
        },
        "environment" = [
          {
            "name"  = "AWS_ROUTE53_ZONE",
            "value" = var.aws_route53_zone,
          },
          {
            "name"  = "DNS_SERVER",
            "value" = cidrhost(aws_vpc.main.cidr_block, 2)
          },
          {
            "name"  = "AWS_REGION",
            "value" = data.aws_region.aws_region.name
          },
          {
            "name"  = "AWS_EC2_HOST",
            "value" = "ec2.${data.aws_region.aws_region.name}.amazonaws.com"
          },
          {
            "name"  = "VPC_ID",
            "value" = aws_vpc.notebooks.id
          },
          {
            "name"  = "IP_ADDRESS",
            "value" = aws_lb.dns_rewrite_proxy_new.subnet_mapping.*.private_ipv4_address[0]
        }]
      }
  ])

  execution_role_arn       = aws_iam_role.dns_rewrite_proxy_task_execution.arn
  task_role_arn            = aws_iam_role.dns_rewrite_proxy_task.arn
  network_mode             = "awsvpc"
  cpu                      = local.dns_rewrite_proxy_container_cpu
  memory                   = local.dns_rewrite_proxy_container_memory
  requires_compatibilities = ["FARGATE"]

  lifecycle {
    ignore_changes = [
      revision,
    ]
  }
}

data "external" "dns_rewrite_proxy_current_tag" {
  program = ["${path.module}/container-tag.sh"]

  query = {
    cluster_name   = "${aws_ecs_cluster.main_cluster.name}"
    service_name   = "${var.prefix}-dns-rewrite-proxy-new" # Manually specified to avoid a cycle
    container_name = "${local.dns_rewrite_proxy_container_name}"
  }
}

resource "aws_cloudwatch_log_group" "dns_rewrite_proxy" {
  name              = "${var.prefix}-dns-rewrite-proxy"
  retention_in_days = "3653"
}

resource "aws_cloudwatch_log_subscription_filter" "dns_rewrite_proxy" {
  count           = var.cloudwatch_subscription_filter ? 1 : 0
  name            = "${var.prefix}-dns-rewrite-proxy"
  log_group_name  = aws_cloudwatch_log_group.dns_rewrite_proxy.name
  filter_pattern  = ""
  destination_arn = var.cloudwatch_destination_arn
}

resource "aws_iam_role" "dns_rewrite_proxy_task_execution" {
  name               = "${var.prefix}-dns-rewrite-proxy-task-execution"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.dns_rewrite_proxy_task_execution_ecs_tasks_assume_role.json
}

data "aws_iam_policy_document" "dns_rewrite_proxy_task_execution_ecs_tasks_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "dns_rewrite_proxy_task_execution" {
  role       = aws_iam_role.dns_rewrite_proxy_task_execution.name
  policy_arn = aws_iam_policy.dns_rewrite_proxy_task_execution.arn
}

resource "aws_iam_policy" "dns_rewrite_proxy_task_execution" {
  name   = "${var.prefix}-dns-rewrite-proxy-task-execution"
  path   = "/"
  policy = data.aws_iam_policy_document.dns_rewrite_proxy_task_execution.json
}

data "aws_iam_policy_document" "dns_rewrite_proxy_task_execution" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "${aws_cloudwatch_log_group.dns_rewrite_proxy.arn}:*",
    ]
  }

  statement {
    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]

    resources = [
      "${aws_ecr_repository.dns_rewrite_proxy.arn}",
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

resource "aws_iam_role" "dns_rewrite_proxy_task" {
  name               = "${var.prefix}-dns-rewrite-proxy-task"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.dns_rewrite_proxy_task_ecs_tasks_assume_role.json
}

resource "aws_iam_role_policy_attachment" "dns_rewrite_proxy" {
  role       = aws_iam_role.dns_rewrite_proxy_task.name
  policy_arn = aws_iam_policy.dns_rewrite_proxy_task.arn
}

resource "aws_iam_policy" "dns_rewrite_proxy_task" {
  name   = "${var.prefix}-dns-rewrite-proxy-task"
  path   = "/"
  policy = data.aws_iam_policy_document.dns_rewrite_proxy_task.json
}

data "aws_iam_policy_document" "dns_rewrite_proxy_task" {
  statement {
    actions = [
      "ec2:AssociateDhcpOptions",
      "ec2:CreateDhcpOptions",
      "ec2:CreateTags",
      "ec2:DeleteDhcpOptions",
      "ec2:DescribeVpcs",
    ]

    resources = [
      "*",
    ]
  }
}

data "aws_iam_policy_document" "dns_rewrite_proxy_task_ecs_tasks_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}
