resource "aws_vpc_endpoint" "lambda_to_rds" {
  vpc_id              = var.vpc_id_datasets
  service_name        = "com.amazonaws.eu-west-2.lambda"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  security_group_ids = [var.datasets_security_group_id]
  subnet_ids         = var.datasets_subnet_ids
  policy             = data.aws_iam_policy_document.lambda_endpoint_policy.json
}


// TODO: these permissions are excessive, given due to current non-working status to explore correct values
data "aws_iam_policy_document" "lambda_endpoint_policy" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "*",
    ]
    resources = [
      "*"
    ]
  }
}


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


// TODO: these permissions are excessive, given due to current non-working status to explore correct values
data "aws_iam_policy_document" "lambda_sns_to_rds" {
  statement {
    actions   = ["SNS:Receive", "SNS:Subscribe"]
    effect    = "Allow"
    resources = [var.sns_success_topic_arn, var.sns_error_topic_arn]
  }
  statement {
    actions   = ["rds-db:connect", "rds-data:ExecuteStatement", "rds-data:ExecuteSql", "rds-data:BatchExecuteStatement", "rds-data:BeginTransaction", "rds-data:CommitTransaction", "rds-data:RollbackTransaction"]
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
    actions = ["ec2:DescribeNetworkInterfaces",
      "ec2:DescribeSubnets",
      "ec2:CreateNetworkInterface",
      "ec2:DeleteNetworkInterface",
      "ec2:AssignPrivateIpAddresses",
      "ec2:UnassignPrivateIpAddresses",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeVpcs",
      "ec2:getSecurityGroupsForVpc",
    ]
    effect    = "Allow"
    resources = ["*"]
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
  timeout          = 30
  layers           = [var.lambda_layer_pyscopg3_arn]
  environment {
    variables = {
      DATASETS_DB_USERNAME   = var.datasets_db_username
      DATASETS_DB_PASSWORD   = var.datasets_db_password
      DATASETS_DB_HOST       = var.datasets_db_host
      DATASETS_DB_PORT       = var.datasets_db_port
      DATASETS_DB_NAME       = var.datasets_db_name
      DATASETS_DB_ARN        = var.datasets_db_arn
      DATASETS_DB_SECRET_ARN = var.datasets_db_secret_arn
    }
  }
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
