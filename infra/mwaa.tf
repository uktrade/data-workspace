# SECURITY GROUP
resource "aws_security_group" "mwaa" {
  count       = var.mwaa_environment_name != "" ? 1 : 0
  name        = var.mwaa_environment_name
  vpc_id      = aws_vpc.main.id
  description = var.mwaa_environment_name

  tags = {
    Name = "mwaa-${var.mwaa_environment_name}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "mwaa_ingress_postgres" {
  count                    = var.mwaa_environment_name != "" ? 1 : 0
  description              = "Ingress PostgreSQL"
  type                     = "ingress"
  from_port                = "5432"
  to_port                  = "5432"
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.mwaa[0].id
  security_group_id        = aws_security_group.mwaa[0].id
}

resource "aws_security_group_rule" "mwaa_ingress_https" {
  count                    = var.mwaa_environment_name != "" ? 1 : 0
  description              = "Ingress HTTPS"
  type                     = "ingress"
  from_port                = "443"
  to_port                  = "443"
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.mwaa[0].id
  security_group_id        = aws_security_group.mwaa[0].id
}

resource "aws_security_group_rule" "mwaa_egress_all" {
  count             = var.mwaa_environment_name != "" ? 1 : 0
  description       = "Egress all"
  type              = "egress"
  from_port         = "0"
  to_port           = "65535"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.mwaa[0].id
}


# IAM
resource "aws_iam_role" "mwaa_execution_role" {
  count              = var.mwaa_environment_name != "" ? 1 : 0
  name               = "${var.prefix}-${var.mwaa_environment_name}-mwaa-execution-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy[0].json
}

data "aws_iam_policy_document" "assume_role_policy" {
  count = var.mwaa_environment_name != "" ? 1 : 0
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["airflow-env.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "mwaa_execution_role_policy" {
  count = var.mwaa_environment_name != "" ? 1 : 0
  statement {
    effect = "Allow"
    actions = [
      "airflow:PublishMetrics"
    ]
    resources = [
      "arn:aws:airflow:${data.aws_region.aws_region.name}:${data.aws_caller_identity.aws_caller_identity.account_id}:environment/${var.mwaa_environment_name}*"
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
      "arn:aws:s3:::${aws_s3_bucket.mwaa_source_bucket[0].bucket}",
      "arn:aws:s3:::${aws_s3_bucket.mwaa_source_bucket[0].bucket}/*"
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
      "arn:aws:logs:${data.aws_region.aws_region.name}:${data.aws_caller_identity.aws_caller_identity.account_id}:log-group:airflow-${var.mwaa_environment_name}-*"
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
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = [
      "arn:aws:secretsmanager:${data.aws_region.aws_region.name}:${data.aws_caller_identity.aws_caller_identity.account_id}:secret:${var.mwaa_environment_name}/*"
    ]
  }
}

resource "aws_iam_policy" "mwaa_execution_role_policy" {
  count  = var.mwaa_environment_name != "" ? 1 : 0
  name   = "${var.mwaa_environment_name}-execution-role-policy"
  policy = data.aws_iam_policy_document.mwaa_execution_role_policy[0].json
}

resource "aws_iam_role_policy_attachment" "mwaa_execution_role_policy_attachment" {
  count      = var.mwaa_environment_name != "" ? 1 : 0
  role       = aws_iam_role.mwaa_execution_role[0].name
  policy_arn = aws_iam_policy.mwaa_execution_role_policy[0].arn
}

# S3
resource "aws_s3_bucket" "mwaa_source_bucket" {
  count         = var.mwaa_environment_name != "" ? 1 : 0
  bucket        = var.mwaa_source_bucket_name
  force_destroy = false
}

resource "aws_s3_bucket_versioning" "mwaa_source_bucket" {
  count  = var.mwaa_environment_name != "" ? 1 : 0
  bucket = aws_s3_bucket.mwaa_source_bucket[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

# MWAA
resource "aws_mwaa_environment" "mwaa" {
  count                  = var.mwaa_environment_name != "" ? 1 : 0
  name                   = var.mwaa_environment_name
  environment_class      = "mw1.small" # mw1.small, mw1.medium, mw1.large
  dag_s3_path            = "dags/"
  execution_role_arn     = aws_iam_role.mwaa_execution_role[0].arn
  source_bucket_arn      = aws_s3_bucket.mwaa_source_bucket[0].arn
  airflow_version        = "2.8.1"
  schedulers             = 2
  min_workers            = 1
  max_workers            = 10
  requirements_s3_path   = "requirements.txt"
  startup_script_s3_path = aws_s3_object.mwaa_source_bucket_startup_script[0].key

  webserver_access_mode = "PUBLIC_ONLY"

  airflow_configuration_options = {
    "core.default_task_retries" = 6
    "core.parallelism"          = 1
  }

  lifecycle {
    ignore_changes = [
      requirements_s3_object_version,
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
      log_level = "INFO"
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
    security_group_ids = ["${aws_security_group.mwaa[0].id}"]
    subnet_ids         = slice(aws_subnet.private_with_egress.*.id, 0, 2)
  }
}

resource "aws_s3_object" "mwaa_source_bucket_startup_script" {
  key    = "startup.sh"
  count  = var.mwaa_environment_name != "" ? 1 : 0
  bucket = aws_s3_bucket.mwaa_source_bucket[0].id
  content = templatefile(
    "${path.module}/startup.sh", {
      secret_name = var.mwaa_environment_name
    }
  )
}
