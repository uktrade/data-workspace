resource "aws_iam_role" "lambda_sns_to_rds" {
  name = "${var.prefix}-iam-for-lambda-sns-to-rds"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
  }] })
}


resource "aws_iam_role_policy" "lambda_sns_to_rds" {
  name   = "${var.prefix}-policy-for-lambda-sns-to-rds"
  role   = aws_iam_role.lambda_sns_to_rds.id
  policy = data.aws_iam_policy_document.lambda_sns_to_rds.json
}


data "aws_iam_policy_document" "lambda_sns_to_rds" {
  statement {
    actions   = ["SNS:Receive", "SNS:Subscribe"]
    effect    = "Allow"
    resources = [var.sns_success_topic_arn, var.sns_error_topic_arn]
  }
  statement {
    actions   = ["rds-db:connect"]
    effect    = "Allow"
    resources = [var.datasets_db_arn]
  }
  statement {
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents", "logs:DescribeLogStreams"]
    effect    = "Allow"
    resources = ["arn:aws:logs:*:*:*"]
  }
  statement {
    actions   = ["s3:GetObject"]
    effect    = "Allow"
    resources = ["${var.notebooks_s3_bucket_arn}/*"]
  }
  statement {
    actions   = ["ec2:DescribeNetworkInterfaces", "ec2:DescribeSubnets", "ec2:AssignPrivateIpAddresses", "ec2:UnassignPrivateIpAddresses", "ec2:DescribeSecurityGroups", "ec2:DescribeSubnets", "ec2:DescribeVpcs", "ec2:getSecurityGroupsForVpc"]
    effect    = "Allow"
    resources = ["*"]
  }
  statement {
    actions   = ["ec2:DeleteNetworkInterface", "ec2:CreateNetworkInterface"]
    effect    = "Allow"
    resources = ["arn:aws:ec2:${var.aws_region}:${var.account_id}:*/*"]
  }
  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    effect    = "Allow"
    resources = [var.datasets_db_secret_arn]
  }
}


data "archive_file" "lambda_payload" {
  type        = "zip"
  source_file = "${path.module}/lambda_function/sns_to_rds.py"
  output_path = "${path.module}/lambda_function/payload.zip"
}


resource "aws_lambda_function" "lambda_sns_to_rds" {
  filename         = data.archive_file.lambda_payload.output_path
  source_code_hash = data.archive_file.lambda_payload.output_base64sha256
  function_name    = "${var.prefix}-sns-to-rds"
  role             = aws_iam_role.lambda_sns_to_rds.arn
  handler          = "sns_to_rds.lambda_handler"
  runtime          = "python3.12"
  timeout          = 60
  layers           = [var.lambda_layer_pyscopg3_arn]
  environment {
    variables = {
      DATASETS_DB_USERNAME   = var.datasets_db_username
      DATASETS_DB_HOST       = var.datasets_db_host
      DATASETS_DB_PORT       = var.datasets_db_port
      DATASETS_DB_NAME       = var.datasets_db_name
      DATASETS_DB_SECRET_ARN = var.datasets_db_secret_arn
    }
  }
  vpc_config {
    subnet_ids         = var.datasets_subnet_ids
    security_group_ids = [aws_security_group.lambda_sns_to_rds.id]
  }
}


resource "aws_security_group" "lambda_sns_to_rds" {
  name   = "${var.prefix}-datasets-vpc-lambda-sns-to-rds"
  vpc_id = var.vpc_id_datasets

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "vpc_endpoints" {
  name   = "${var.prefix}-datasets-vpc-endpoints"
  vpc_id = var.vpc_id_datasets

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_vpc_security_group_ingress_rule" "datasets_db_lambda" {
  security_group_id            = var.datasets_security_group_id
  referenced_security_group_id = aws_security_group.lambda_sns_to_rds.id
  from_port                    = var.datasets_db_port
  to_port                      = var.datasets_db_port
  ip_protocol                  = "tcp"
}


resource "aws_vpc_security_group_egress_rule" "datasets_db_lambda" {
  security_group_id            = aws_security_group.lambda_sns_to_rds.id
  referenced_security_group_id = var.datasets_security_group_id
  from_port                    = var.datasets_db_port
  to_port                      = var.datasets_db_port
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "https" {
  security_group_id            = aws_security_group.vpc_endpoints.id
  referenced_security_group_id = aws_security_group.lambda_sns_to_rds.id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "https" {
  security_group_id            = aws_security_group.lambda_sns_to_rds.id
  referenced_security_group_id = aws_security_group.vpc_endpoints.id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
}


resource "aws_sns_topic_subscription" "success_topic_lambda" {
  topic_arn = var.sns_success_topic_arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.lambda_sns_to_rds.arn
}


resource "aws_sns_topic_subscription" "error_topic_lambda" {
  topic_arn = var.sns_error_topic_arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.lambda_sns_to_rds.arn
}


resource "aws_lambda_permission" "success_with_sns" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_sns_to_rds.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = var.sns_success_topic_arn
}


resource "aws_lambda_permission" "error_with_sns" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_sns_to_rds.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = var.sns_error_topic_arn
}


resource "aws_vpc_endpoint" "datasets_secretsmanager_endpoint" {
  vpc_id              = var.vpc_id_datasets
  service_name        = "com.amazonaws.${var.aws_region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.datasets_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  policy              = data.aws_iam_policy_document.datasets_secretsmanager_endpoint.json
  auto_accept         = true
  private_dns_enabled = true
}


data "aws_iam_policy_document" "datasets_secretsmanager_endpoint" {
  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    effect    = "Allow"
    resources = [var.datasets_db_secret_arn]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}
