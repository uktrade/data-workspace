resource "aws_ecs_cluster" "matchbox" {
  name = "${var.prefix}-matchbox"
}

resource "aws_ecs_service" "matchbox" {
  count = var.matchbox_on ? 1 : 0

  name                              = "${var.prefix}-matchbox-${var.matchbox_environment}"
  cluster                           = aws_ecs_cluster.matchbox.id
  task_definition                   = aws_ecs_task_definition.matchbox_service[count.index].arn
  desired_count                     = 1
  launch_type                       = "FARGATE"
  deployment_maximum_percent        = 200
  platform_version                  = "1.4.0"
  health_check_grace_period_seconds = "10"

  load_balancer {
    target_group_arn = aws_lb_target_group.matchbox[0].arn
    container_port   = local.matchbox_api_port
    container_name   = "matchbox"
  }

  service_registries {
    registry_arn = aws_service_discovery_service.matchbox[0].arn
  }

  network_configuration {
    subnets         = ["${aws_subnet.matchbox_private.*.id[0]}"]
    security_groups = ["${aws_security_group.matchbox_service[count.index].id}"]
  }

  depends_on = [
    aws_lb_listener.matchbox
  ]
}

resource "aws_service_discovery_service" "matchbox" {
  count = var.matchbox_on ? 1 : 0
  name  = "${var.prefix}-matchbox-api"

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
  count = var.matchbox_on ? 1 : 0

  family = "${var.prefix}-matchbox-${var.matchbox_environment}"
  container_definitions = jsonencode([
    {
      "environment" = [
        {
          "name"  = "DATABASE_URI",
          "value" = "postgresql://${aws_rds_cluster.matchbox[count.index].master_username}:${random_password.db_password[count.index].result}@${aws_rds_cluster.matchbox[count.index].endpoint}:5432/${aws_rds_cluster.matchbox[count.index].database_name}"
        },
        {
          "name"  = "DATABASE_URI_READONLY",
          "value" = "postgresql://${aws_rds_cluster.matchbox[count.index].master_username}:${random_password.db_password[count.index].result}@${aws_rds_cluster.matchbox[count.index].reader_endpoint}:5432/${aws_rds_cluster.matchbox[count.index].database_name}"
        },
        {
          "name"  = "AWS_DEFAULT_REGION",
          "value" = "eu-west-2"
        },
        {
          "name"  = "MB__SERVER__DATASTORE__CACHE_BUCKET_NAME",
          "value" = "${var.matchbox_s3_cache}-${var.matchbox_environment}"
        },
        {
          "name"  = "MB__CLIENT__API_ROOT",
          "value" = ""
        },
        {
          "name"  = "MB__SERVER__BACKEND_TYPE",
          "value" = "postgres"
        },
        {
          "name"  = "MB__SERVER__POSTGRES__HOST",
          "value" = aws_rds_cluster.matchbox[count.index].endpoint
        },
        {
          "name"  = "MB__SERVER__POSTGRES__PORT",
          "value" = "5432"
        },
        {
          "name"  = "MB__SERVER__POSTGRES__USER",
          "value" = aws_rds_cluster.matchbox[count.index].master_username
        },
        {
          "name"  = "MB__SERVER__POSTGRES__PASSWORD",
          "value" = random_password.db_password[count.index].result
        },
        {
          "name"  = "MB__SERVER__POSTGRES__DATABASE",
          "value" = aws_rds_cluster.matchbox[count.index].database_name
        },
        {
          "name"  = "MB__SERVER__POSTGRES__DB_SCHEMA",
          "value" = "mb"
        },
        {
          "name"  = "MB__SERVER__API_KEY",
          "value" = var.matchbox_api_key
        },
        {
          "name"  = "MB__SERVER__LOG_LEVEL",
          "value" = var.matchbox_server_loglevel
        },
        {
          "name"  = "MB__SERVER__BATCH_SIZE",
          "value" = "250_000"
        },
        {
          "name"  = "SENTRY_MATCHBOX_DSN",
          "value" = var.sentry_matchbox_dsn
        },
        {
          "name"  = "DD_AGENT_HOST",
          "value" = "127.0.0.1"
        }
      ],
      "essential"   = true,
      "image"       = "${aws_ecr_repository.matchbox[0].repository_url}:master",
      "networkMode" = "awsvpc",
      "logConfiguration" = {
        "logDriver" = "awslogs",
        "options" = {
          "awslogs-group"         = aws_cloudwatch_log_group.matchbox[0].name,
          "awslogs-region"        = data.aws_region.aws_region.name,
          "awslogs-stream-prefix" = "matchbox"
        }
      },
      "memoryReservation" = var.matchbox_api_container_resources.memory,
      "cpu"               = var.matchbox_api_container_resources.cpu
      "mountPoints"       = [],
      "name"              = "matchbox",
      "portMappings" = [{
        "containerPort" = 8000,
        "hostPort"      = 8000,
        "protocol"      = "tcp"
      }]
      }, {
      "environment" = [
        {
          "name"  = "DD_API_KEY",
          "value" = var.matchbox_datadog_api_key
        },
        {
          "name"  = "DD_SERVICE",
          "value" = "matchbox"
        },
        {
          "name"  = "DD_ENV",
          "value" = var.matchbox_environment
        },
        {
          "name"  = "DD_APM_ENABLED",
          "value" = "true"
        },
        {
          "name"  = "DD_APM_NON_LOCAL_TRAFFIC",
          "value" = "true"
        },
        {
          "name"  = "DD_LOGS_ENABLED",
          "value" = "true"
        },
        {
          "name"  = "DD_PROFILING_ENABLED",
          "value" = "true"
        },
        {
          "name"  = "DD_PROCESS_AGENT_PROCESS_COLLECTION_ENABLED",
          "value" = "true"
        },
        {
          "name"  = "DD_SITE",
          "value" = "datadoghq.eu"
        }
      ],
      "essential"   = true,
      "image"       = "${aws_ecr_repository.datadog.repository_url}:7",
      "networkMode" = "awsvpc",
      "logConfiguration" = {
        "logDriver" = "awslogs",
        "options" = {
          "awslogs-group"         = aws_cloudwatch_log_group.matchbox[0].name,
          "awslogs-region"        = data.aws_region.aws_region.name,
          "awslogs-stream-prefix" = "datadog-agent"
        }
      },
      "mountPoints" = [],
      "name"        = "datadog-agent"
    }
  ])

  execution_role_arn = aws_iam_role.matchbox_task_execution[count.index].arn
  task_role_arn      = aws_iam_role.matchbox_task[count.index].arn
  network_mode       = "awsvpc"

  cpu    = var.matchbox_api_container_resources.cpu
  memory = var.matchbox_api_container_resources.memory

  requires_compatibilities = ["FARGATE"]
  tags                     = {}

  lifecycle {
    ignore_changes = [
      revision,
    ]
  }
}

resource "aws_iam_role" "matchbox_task_execution" {
  count = var.matchbox_on ? 1 : 0

  name               = "${var.prefix}-matchbox-task-execution-${var.matchbox_environment}"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.matchbox_task_execution_ecs_tasks_assume_role[count.index].json
}

data "aws_iam_policy_document" "matchbox_task_execution_ecs_tasks_assume_role" {
  count = var.matchbox_on ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "matchbox_task_execution" {
  count = var.matchbox_on ? 1 : 0

  role       = aws_iam_role.matchbox_task_execution[count.index].name
  policy_arn = aws_iam_policy.matchbox_task_execution[count.index].arn
}

resource "aws_iam_policy" "matchbox_task_execution" {
  count = var.matchbox_on ? 1 : 0

  name   = "${var.prefix}-matchbox-${var.matchbox_environment}-task-execution"
  path   = "/"
  policy = data.aws_iam_policy_document.matchbox_task_execution[count.index].json
}

data "aws_iam_policy_document" "matchbox_task_execution" {
  count = var.matchbox_on ? 1 : 0

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
  count = var.matchbox_on ? 1 : 0

  name               = "${var.prefix}-matchbox-${var.matchbox_environment}-task"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.matchbox_task_ecs_tasks_assume_role[count.index].json
}

data "aws_iam_policy_document" "matchbox_task_ecs_tasks_assume_role" {
  count = var.matchbox_on ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "matchbox_task" {
  count = var.matchbox_on ? 1 : 0

  role       = aws_iam_role.matchbox_task[count.index].name
  policy_arn = aws_iam_policy.matchbox_task[count.index].arn
}

resource "aws_iam_policy" "matchbox_task" {
  count = var.matchbox_on ? 1 : 0

  name   = "${var.prefix}-matchbox-${var.matchbox_environment}-task"
  path   = "/"
  policy = data.aws_iam_policy_document.matchbox_task[count.index].json
}

data "aws_iam_policy_document" "matchbox_task" {
  count = var.matchbox_on ? 1 : 0

  statement {
    actions = [
      "s3:*",
    ]

    resources = ["arn:aws:s3:::${aws_s3_bucket.matchbox_s3_cache[0].id}", "arn:aws:s3:::${aws_s3_bucket.matchbox_s3_cache[0].id}/*"]
  }
}

resource "aws_cloudwatch_log_group" "matchbox" {
  count = var.matchbox_on ? 1 : 0

  name              = "${var.prefix}-matchbox"
  retention_in_days = "3653"
}

resource "aws_cloudwatch_log_subscription_filter" "matchbox" {
  count = var.cloudwatch_subscription_filter && var.matchbox_on ? 1 : 0

  name            = "${var.prefix}-matchbox"
  log_group_name  = aws_cloudwatch_log_group.matchbox[count.index].name
  filter_pattern  = ""
  destination_arn = var.cloudwatch_destination_arn
}

resource "aws_cloudwatch_log_subscription_filter" "matchbox_datadog" {
  count = var.cloudwatch_destination_datadog_arn != "" && var.matchbox_on ? 1 : 0

  name            = "${var.prefix}-matchbox-datadog"
  log_group_name  = aws_cloudwatch_log_group.matchbox[count.index].name
  filter_pattern  = ""
  destination_arn = var.cloudwatch_destination_datadog_arn
  role_arn        = aws_iam_role.matchbox_datadog_logs[0].arn
}

resource "aws_iam_role" "matchbox_datadog_logs" {
  count = var.cloudwatch_destination_datadog_arn != "" && var.matchbox_on ? 1 : 0

  name = "${var.prefix}-matchbox-datadog-logs"
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
  count = var.cloudwatch_destination_datadog_arn != "" && var.matchbox_on ? 1 : 0

  name = "${var.prefix}-matchbox-datadog-logs"
  role = aws_iam_role.matchbox_datadog_logs[0].id

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

resource "aws_security_group" "matchbox_service" {
  count = var.matchbox_on ? 1 : 0

  name        = "${var.prefix}-matchbox-${var.matchbox_environment}-service"
  description = "${var.prefix}-matchbox-${var.matchbox_environment}-service"
  vpc_id      = aws_vpc.matchbox[0].id

  tags = {
    Name = "${var.prefix}-matchbox-${var.matchbox_environment}-service"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "matchbox_db_https_ingress_from_matchbox_service" {
  count = var.matchbox_on ? 1 : 0

  description              = "ingress-https-to-matchbox-db"
  security_group_id        = aws_security_group.matchbox_db[count.index].id
  source_security_group_id = aws_security_group.matchbox_service[count.index].id

  type      = "ingress"
  from_port = local.matchbox_db_port
  to_port   = local.matchbox_db_port
  protocol  = "tcp"
}

resource "aws_security_group_rule" "matchbox_service_egress_udp_to_dns_rewrite_proxy" {
  count = var.matchbox_on ? 1 : 0

  description       = "egress-dns-to-dns-rewrite-proxy"
  security_group_id = aws_security_group.matchbox_service[count.index].id
  cidr_blocks       = ["${aws_subnet.private_with_egress.*.cidr_block[0]}"]

  type      = "egress"
  from_port = "53"
  to_port   = "53"
  protocol  = "udp"
}

resource "aws_security_group_rule" "matchbox_egress_https_datadog" {
  count = var.matchbox_on ? 1 : 0

  description       = "egress-https-to-datadog"
  security_group_id = aws_security_group.matchbox_service[count.index].id
  # From https://ip-ranges.datadoghq.eu/
  cidr_blocks = [
    "34.107.147.46/32",
    "34.107.148.131/32",
    "34.107.178.244/32",
    "34.107.236.155/32",
    "34.110.210.251/32",
    "34.117.189.27/32",
    "34.117.37.81/32",
    "34.120.15.173/32",
    "34.120.31.75/32",
    "34.120.57.90/32",
    "34.120.77.189/32",
    "34.120.96.217/32",
    "34.149.115.128/26",
    "34.149.135.19/32",
    "34.149.169.145/32",
    "34.149.206.161/32",
    "34.149.254.123/32",
    "34.149.49.28/32",
    "34.149.78.213/32",
    "34.160.168.175/32",
    "34.160.186.117/32",
    "34.160.253.227/32",
    "34.160.51.118/32",
    "34.95.101.191/32",
    "34.96.71.221/32",
    "34.98.110.196/32",
    "34.98.83.239/32",
    "34.98.95.189/32",
    "35.190.39.146/32",
    "35.190.78.95/32",
    "35.190.9.84/32",
    "35.201.126.123/32",
    "35.227.218.104/32",
    "35.227.223.199/32",
    "35.241.39.98/32",
    "35.244.140.126/32",
    "35.244.180.206/32",
    "35.244.221.148/32",
  ]

  type      = "egress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "matchbox_egress_https_to_matchbox_endpoints" {
  count = var.matchbox_on ? 1 : 0

  description              = "egress-https-from-matchbox-service"
  security_group_id        = aws_security_group.matchbox_service[count.index].id
  source_security_group_id = aws_security_group.matchbox_endpoints[0].id

  type      = "egress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "matchbox_service_egress_https_to_matchbox_db" {
  count = var.matchbox_on ? 1 : 0

  description              = "egress-matchbox-service"
  security_group_id        = aws_security_group.matchbox_service[count.index].id
  source_security_group_id = aws_security_group.matchbox_db[count.index].id

  type      = "egress"
  from_port = local.matchbox_db_port
  to_port   = local.matchbox_db_port
  protocol  = "tcp"
}

resource "aws_security_group_rule" "matchbox_egress_https_to_matchbox_s3_endpoint" {
  count = var.matchbox_on ? 1 : 0

  description       = "egress-https-to-s3"
  security_group_id = aws_security_group.matchbox_service[count.index].id
  prefix_list_ids   = [aws_vpc_endpoint.matchbox_endpoint_s3[0].prefix_list_id]

  type      = "egress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "matchbox_endpoints_https_ingress_from_matchbox_service" {
  count = var.matchbox_on ? 1 : 0

  description              = "ingress-matchbox-endpoints"
  security_group_id        = aws_security_group.matchbox_endpoints[0].id
  source_security_group_id = aws_security_group.matchbox_service[count.index].id

  type      = "ingress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}
