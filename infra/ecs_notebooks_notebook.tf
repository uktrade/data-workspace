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

  statement {
    actions = [
      "elasticfilesystem:ClientMount",
      "elasticfilesystem:ClientWrite",
    ]

    condition {
      test     = "StringEquals"
      variable = "elasticfilesystem:AccessPointArn"
      values = [
        "arn:aws:elasticfilesystem:${data.aws_region.aws_region.name}:${data.aws_caller_identity.aws_caller_identity.account_id}:access-point/__ACCESS_POINT_ID__"
      ]
    }

    resources = [
      "${aws_efs_file_system.notebooks.arn}",
    ]
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

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.notebooks.id
  service_name      = "com.amazonaws.${data.aws_region.aws_region.name}.s3"
  vpc_endpoint_type = "Gateway"

  policy = data.aws_iam_policy_document.aws_vpc_endpoint_s3_notebooks.json

  timeouts {}
}

data "aws_iam_policy_document" "aws_vpc_endpoint_s3_notebooks" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "s3:ListBucket",
    ]
    resources = concat([
      "${aws_s3_bucket.notebooks.arn}",
      ], [
      for bucket in aws_s3_bucket.mlflow : bucket.arn
    ])
  }

  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject"
    ]

    resources = concat([
      "${aws_s3_bucket.notebooks.arn}/*",
      ], [
      for bucket in aws_s3_bucket.mlflow : "${bucket.arn}/*"
    ])
  }

  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
    ]

    resources = [
      for bucket in aws_s3_bucket.mlflow : bucket.arn
    ]
  }

  statement {
    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "arn:aws:s3:::${var.mirrors_data_bucket_name != "" ? var.mirrors_data_bucket_name : var.mirrors_bucket_name}/*",
    ]
  }

  statement {
    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "s3:ListBucket",
    ]

    resources = [
      "arn:aws:s3:::${var.mirrors_data_bucket_name != "" ? var.mirrors_data_bucket_name : var.mirrors_bucket_name}",
    ]
  }

  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "s3:GetObject",
    ]

    resources = [
      # For docker to pull from ECR
      "arn:aws:s3:::prod-${data.aws_region.aws_region.name}-starport-layer-bucket/*",
      # For AWS Linux 2 packages
      "arn:aws:s3:::amazonlinux.*.amazonaws.com/*",
    ]
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

  statement {
    actions = [
      "elasticfilesystem:ClientMount",
      "elasticfilesystem:ClientWrite",
    ]

    resources = [
      "${aws_efs_file_system.notebooks.arn}",
    ]
  }
}

resource "aws_vpc_endpoint_route_table_association" "s3" {
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
  route_table_id  = aws_route_table.private_without_egress.id
}

resource "aws_vpc_endpoint" "cloudwatch_logs" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.aws_region.name}.logs"
  vpc_endpoint_type = "Interface"

  security_group_ids = ["${aws_security_group.cloudwatch.id}"]
  subnet_ids         = ["${aws_subnet.private_with_egress.*.id[0]}"]

  policy = data.aws_iam_policy_document.aws_vpc_endpoint_cloudwatch_logs.json

  private_dns_enabled = true
}

data "aws_iam_policy_document" "aws_vpc_endpoint_cloudwatch_logs" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "*",
    ]

    resources = [
      "*",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalAccount"
      values = [
        "${data.aws_caller_identity.aws_caller_identity.account_id}"
      ]
    }
  }
}

resource "aws_vpc_endpoint" "cloudwatch_monitoring" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.aws_region.name}.monitoring"
  vpc_endpoint_type = "Interface"

  security_group_ids = ["${aws_security_group.cloudwatch.id}"]
  subnet_ids         = ["${aws_subnet.private_with_egress.*.id[0]}"]

  policy = data.aws_iam_policy_document.aws_vpc_endpoint_cloudwatch_monitoring.json

  private_dns_enabled = true
}

data "aws_iam_policy_document" "aws_vpc_endpoint_cloudwatch_monitoring" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "*",
    ]

    resources = [
      "*",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalAccount"
      values = [
        "${data.aws_caller_identity.aws_caller_identity.account_id}"
      ]
    }
  }
}
