# SECURITY GROUP
resource "aws_security_group" "mwaa_dataflow" {
  name        = "${var.prefix}-mwaa-dataflow"
  vpc_id      = aws_vpc.main.id
  description = "${var.prefix}-mwaa-dataflow"

  tags = {
    Name = "${var.prefix}-mwaa-dataflow"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "mwaa_dataflow_ingress_rule_for_first_port" {
  description              = "${var.prefix}-ingress-private-with-egress-healthcheck"
  type                     = "ingress"
  from_port                = "5432"
  to_port                  = "5432"
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.mwaa_dataflow.id
  security_group_id        = aws_security_group.mwaa_dataflow.id
}

resource "aws_security_group_rule" "mwaa_dataflow_ingress_rule_for_second_port" {
  description              = "${var.prefix}-ingress-private-with-egress-healthcheck"
  type                     = "ingress"
  from_port                = "443"
  to_port                  = "443"
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.mwaa_dataflow.id
  security_group_id        = aws_security_group.mwaa_dataflow.id
}

resource "aws_security_group_rule" "mwaa_dataflow_egress_rule" {
  description       = "${var.prefix}-ingress-private-with-egress-healthcheck"
  type              = "egress"
  from_port         = "0"
  to_port           = "65535"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.mwaa_dataflow.id
}


# IAM
resource "aws_iam_role" "dataflow_mwaa" {
  name               = "dataflow-mwaa-execution-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["airflow-env.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "dataflow_mwaa_execution_role_policy" {
  statement {
    effect = "Allow"
    actions = [
      "airflow:PublishMetrics"
    ]
    resources = [
      "arn:aws:airflow:${data.aws_region.aws_region.name}:${data.aws_caller_identity.aws_caller_identity.account_id}:environment/${var.mwaa_name}*"
    ]
  }
  statement {
    effect    = "Deny"
    actions   = ["s3:ListAllMyBuckets"]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject*",
      "s3:GetBucket*",
      "s3:List*"
    ]
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.mwaa_dataflow.bucket}",
      "arn:aws:s3:::${aws_s3_bucket.mwaa_dataflow.bucket}/*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:GetAccountPublicAccessBlock"
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
      "logs:PutLogEvents",
      "logs:GetLogEvents",
      "logs:GetLogRecord",
      "logs:GetLogGroupFields",
      "logs:GetQueryResults"
    ]
    resources = [
      "arn:aws:logs:${data.aws_region.aws_region.name}:${data.aws_caller_identity.aws_caller_identity.account_id}:log-group:airflow-${var.mwaa_name}-*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "logs:DescribeLogGroups"
    ]
    resources = [
      "*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "cloudwatch:PutMetricData"
    ]
    resources = [
      "*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "sqs:ChangeMessageVisibility",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
      "sqs:ReceiveMessage",
      "sqs:SendMessage"
    ]
    resources = [
      "arn:aws:sqs:${data.aws_region.aws_region.name}:*:airflow-celery-*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:GenerateDataKey*",
      "kms:Encrypt"
    ]
    not_resources = ["arn:aws:kms:*:${data.aws_caller_identity.aws_caller_identity.account_id}:key/*"]
    condition {
      test     = "StringLike"
      variable = "kms:ViaService"
      values   = ["sqs.${data.aws_region.aws_region.name}.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "dataflow_mwaa_execution_role_policy" {
  name   = "dataflow-mwaa-execution-role-policy"
  policy = data.aws_iam_policy_document.dataflow_mwaa_execution_role_policy.json
}

resource "aws_iam_role_policy_attachment" "dataflow_mwaa_execution_role_policy_attachment" {
  role       = aws_iam_role.dataflow_mwaa.name
  policy_arn = aws_iam_policy.dataflow_mwaa_execution_role_policy.arn
}

# S3
resource "aws_s3_bucket" "mwaa_dataflow" {
  bucket        = "mwaa-dataflow-dbt-2024"
  force_destroy = "false"
}

resource "aws_s3_bucket_versioning" "mwaa_dataflow_versioning" {
  bucket = aws_s3_bucket.mwaa_dataflow.id
  versioning_configuration {
    status = "Enabled"
  }
}

# MWAA
resource "aws_mwaa_environment" "dataflow" {
  count                = var.mwaa_name == "dataflow" ? 1 : 0
  name                 = var.mwaa_name
  environment_class    = "mw1.small" # mw1.small, mw1.medium, mw1.large
  dag_s3_path          = "dags/"
  execution_role_arn   = aws_iam_role.dataflow_mwaa.arn
  source_bucket_arn    = aws_s3_bucket.mwaa_dataflow.arn
  airflow_version      = "2.8.1"
  schedulers           = 2
  min_workers          = 1
  max_workers          = 10
  requirements_s3_path = "requirements.txt"

  webserver_access_mode = "PUBLIC_ONLY"

  airflow_configuration_options = {
    "core.default_task_retries" = 6
    "core.parallelism"          = 1
  }

  lifecycle {
    ignore_changes = [
      requirements_s3_object_version,
      plugins_s3_object_version
    ]
  }

  logging_configuration {

    dag_processing_logs {
      enabled   = true
      log_level = "WARNING"
    }
    scheduler_logs {
      enabled   = true
      log_level = "WARNING"
    }
    task_logs {
      enabled   = true
      log_level = "WARNING"
    }
    webserver_logs {
      enabled   = true
      log_level = "WARNING"
    }
    worker_logs {
      enabled   = true
      log_level = "WARNING"
    }
  }

  network_configuration {
    security_group_ids = ["${aws_security_group.mwaa_dataflow.id}"]
    subnet_ids         = slice(aws_subnet.private_with_egress.*.id, 0, 2)
  }
}
