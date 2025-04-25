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
      "mountPoints" = concat([{
        "sourceVolume"  = "home_directory",
        "containerPath" = "/home/coder"
        }, {
        "sourceVolume"  = "home_directory",
        "containerPath" = "/home/dw-user"
        }], var.tools_efs_on ? [{
        "sourceVolume"  = "efs_storage"
        "containerPath" = "/efs"
      }] : [])
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
  task_role_arn            = aws_iam_role.tools_dummy_task_role.arn
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

  dynamic "volume" {
    for_each = var.tools_efs_on ? [0] : []
    content {
      name = "efs_storage"
      efs_volume_configuration {
        file_system_id     = aws_efs_file_system.notebooks.id
        transit_encryption = "ENABLED"
        authorization_config {
          iam = "ENABLED"
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      revision,
    ]
  }
}

resource "aws_cloudwatch_log_group" "notebook" {
  name              = "${var.prefix}-notebook"
  retention_in_days = "3653"
}

resource "aws_cloudwatch_log_subscription_filter" "notebook" {
  count           = var.cloudwatch_subscription_filter ? 1 : 0
  name            = "${var.prefix}-notebook"
  log_group_name  = aws_cloudwatch_log_group.notebook.name
  filter_pattern  = ""
  destination_arn = var.cloudwatch_destination_arn
}

# this dummy IAM role is required to pass AWS validation
# but this is correctly overriden during spawning in Data Workspace FE
resource "aws_iam_role" "tools_dummy_task_role" {
  name = "${var.prefix}-tools-dummy-task-role"
  path = "/"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Deny"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role" "notebook_task_execution" {
  name               = "${var.prefix}-notebook-task-execution"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.notebook_task_execution_ecs_tasks_assume_role.json
}

data "aws_iam_policy_document" "notebook_task_execution_ecs_tasks_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "notebook_task_execution" {
  role       = aws_iam_role.notebook_task_execution.name
  policy_arn = aws_iam_policy.notebook_task_execution.arn
}

resource "aws_iam_policy" "notebook_task_execution" {
  name   = "${var.prefix}-notebook-task-execution"
  path   = "/"
  policy = data.aws_iam_policy_document.notebook_task_execution.json
}

data "aws_iam_policy_document" "notebook_task_execution" {

  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "${aws_cloudwatch_log_group.notebook.arn}:*",
    ]
  }

  statement {
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
    ]

    resources = [
      "*",
    ]
  }
}

data "aws_iam_policy_document" "notebook_s3_access_ecs_tasks_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    principals {
      type        = "AWS"
      identifiers = ["${aws_iam_role.admin_task.arn}"]
    }
  }
}

data "aws_iam_policy_document" "notebook_s3_access_template" {
  statement {
    actions = [
      "s3:ListBucket",
    ]

    resources = [
      "${aws_s3_bucket.notebooks.arn}",
    ]

    condition {
      test     = "ForAnyValue:StringLike"
      variable = "s3:prefix"
      values   = ["__S3_PREFIXES__"]
    }
  }

  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject"
    ]

    resources = ["__S3_BUCKET_ARNS__"]

  }

  statement {
    actions = [
      "s3:ListBucket",
    ]

    resources = [
      "arn:aws:s3:::${var.mirrors_data_bucket_name != "" ? var.mirrors_data_bucket_name : var.mirrors_bucket_name}",
    ]
  }

  statement {
    actions = [
      "cloudwatch:PutMetricData",
    ]

    resources = [
      "*",
    ]

    condition {
      test     = "StringEquals"
      variable = "cloudwatch:namespace"
      values = [
        "${var.cloudwatch_namespace}/S3Sync"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalAccount"
      values = [
        "${data.aws_caller_identity.aws_caller_identity.account_id}"
      ]
    }
  }

  dynamic "statement" {
    for_each = var.tools_efs_on ? [1] : []

    content {
      actions = [
        "elasticfilesystem:ClientMount",
        "elasticfilesystem:ClientWrite",
      ]

      resources = [
        "${aws_efs_file_system.notebooks.arn}",
      ]
    }
  }

  dynamic "statement" {

    for_each = var.sagemaker_on ? [1] : []

    content {
      actions = [
        "sagemaker:DescribeEndpoint",
        "sagemaker:DescribeEndpointConfig",
        "sagemaker:DescribeModel",
        "sagemaker:InvokeEndpointAsync",
        "sagemaker:ListEndpoints",
        "sagemaker:ListEndpointConfigs",
        "sagemaker:ListModels",
      ]

      resources = [
        "*",
      ]
    }
  }
}

resource "aws_iam_policy" "notebook_task_boundary" {
  name   = "${var.prefix}-notebook-task-boundary"
  policy = data.aws_iam_policy_document.jupyterhub_notebook_task_boundary.json
}

data "aws_iam_policy_document" "jupyterhub_notebook_task_boundary" {
  statement {
    actions = [
      "s3:ListBucket",
    ]

    resources = [
      "${aws_s3_bucket.notebooks.arn}",
    ]
  }

  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject"
    ]

    resources = [
      "${aws_s3_bucket.notebooks.arn}/*",
    ]
  }

  # Allow all tools users to access SageMaker endpoints
  dynamic "statement" {

    for_each = var.sagemaker_on ? [1] : []

    content {
      actions = [
        "sagemaker:DescribeEndpoint",
        "sagemaker:DescribeEndpointConfig",
        "sagemaker:DescribeModel",
        "sagemaker:InvokeEndpointAsync",
        "sagemaker:ListEndpoints",
        "sagemaker:ListEndpointConfigs",
        "sagemaker:ListModels",
      ]

      resources = [
        "*",
      ]
    }
  }

  statement {
    actions = [
      "s3:ListBucket",
    ]

    resources = [
      "arn:aws:s3:::${var.mirrors_data_bucket_name != "" ? var.mirrors_data_bucket_name : var.mirrors_bucket_name}",
    ]
  }

  statement {
    actions = [
      "cloudwatch:PutMetricData",
    ]

    resources = [
      "*",
    ]

    condition {
      test     = "StringEquals"
      variable = "cloudwatch:namespace"
      values = [
        "${var.cloudwatch_namespace}/S3Sync"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalAccount"
      values = [
        "${data.aws_caller_identity.aws_caller_identity.account_id}"
      ]
    }
  }

  dynamic "statement" {
    for_each = var.tools_efs_on ? [1] : []

    content {
      actions = [
        "elasticfilesystem:ClientMount",
        "elasticfilesystem:ClientWrite",
      ]

      resources = [
        "${aws_efs_file_system.notebooks.arn}",
      ]
    }
  }
}

# Tools/notebooks can connect to security groups in other VPCs, but they need the peering
# connections setup first, and so we have to manually specify depends_on for this.

resource "aws_security_group" "notebooks" {
  name        = "${var.prefix}-notebooks"
  description = "${var.prefix}-notebooks"
  vpc_id      = aws_vpc.notebooks.id

  tags = {
    Name = "${var.prefix}-notebooks"
  }

  lifecycle {
    create_before_destroy = true
  }
}

module "tools_outgoing_https_vpc_endpoints" {
  source = "./modules/security_group_client_server_connections"

  client_security_groups = [aws_security_group.notebooks]
  server_security_groups = concat([
    aws_security_group.ecr_api,
    aws_security_group.ecr_dkr,
    aws_security_group.cloudwatch,
    ], var.sagemaker_on ? [
    aws_security_group.sagemaker_vpc_endpoints_main[0]] : []
  )
  server_prefix_list_ids = [
    aws_vpc_endpoint.s3.prefix_list_id
  ]
  ports = [443]

  depends_on = [aws_vpc_peering_connection.jupyterhub]
}

module "tools_outgoing_https_sentry_proxy" {
  source = "./modules/security_group_client_server_connections"

  client_security_groups = [aws_security_group.notebooks]
  server_security_groups = [aws_security_group.sentryproxy_service]
  ports                  = [443]

  depends_on = [aws_vpc_peering_connection.jupyterhub]
}

module "tools_outgoing_ssh_gitlab" {
  count  = var.gitlab_on ? 1 : 0
  source = "./modules/security_group_client_server_connections"

  client_security_groups = [aws_security_group.notebooks]
  server_security_groups = [aws_security_group.gitlab_service[0]]
  ports                  = [22]

  depends_on = [aws_vpc_peering_connection.jupyterhub]
}

module "tools_outgoing_mlflow" {
  count  = length(var.mlflow_instances)
  source = "./modules/security_group_client_server_connections"

  client_security_groups = [aws_security_group.notebooks]
  server_security_groups = [aws_security_group.mlflow_service[count.index]]
  ports                  = [local.mlflow_port]
}

module "tools_outgoing_matchbox_api" {
  count  = var.matchbox_on ? length(var.matchbox_instances) : 0
  source = "./modules/security_group_client_server_connections"

  client_security_groups = [aws_security_group.notebooks]
  server_security_groups = [aws_security_group.matchbox_service[count.index]]
  ports                  = [local.matchbox_api_port]

  depends_on = [aws_vpc_peering_connection.matchbox_to_notebooks[0]]
}

module "tools_outgoing_matchbox_dev_db" {
  source = "./modules/security_group_client_server_connections"
  count  = var.matchbox_on && var.matchbox_dev_mode_on ? length(var.matchbox_instances) : 0

  client_security_groups = [aws_security_group.notebooks]
  server_security_groups = [aws_security_group.matchbox_db[count.index]]
  ports                  = [local.matchbox_db_port]

  depends_on = [aws_vpc_peering_connection.matchbox_to_notebooks[0]]
}

module "tools_outgoing_postgresql" {
  source = "./modules/security_group_client_server_connections"

  client_security_groups = [aws_security_group.notebooks]
  server_security_groups = [aws_security_group.datasets]
  ports                  = [aws_rds_cluster_instance.datasets.port]

  depends_on = [aws_vpc_peering_connection.datasets_to_notebooks]
}

module "tools_outgoing_arango" {
  count  = var.arango_on ? 1 : 0
  source = "./modules/security_group_client_server_connections"

  client_security_groups = [aws_security_group.notebooks]
  server_security_groups = [aws_security_group.arango_lb[0]]
  ports                  = [local.arango_container_port]

  depends_on = [aws_vpc_peering_connection.datasets_to_notebooks]
}

module "tools_outgoing_nfs" {
  source = "./modules/security_group_client_server_connections"

  client_security_groups = [aws_security_group.notebooks]
  server_security_groups = [aws_security_group.efs_mount_target_notebooks]
  ports                  = [2049]

  depends_on = [aws_vpc_peering_connection.jupyterhub]
}

module "tools_outgoing_dns" {
  source = "./modules/security_group_client_server_connections"

  client_security_groups = [aws_security_group.notebooks]
  server_ipv4_cidrs      = ["${aws_subnet.private_with_egress.*.cidr_block[0]}"]
  ports                  = [53]
  protocol               = "udp"

  depends_on = [aws_vpc_peering_connection.jupyterhub]
}
