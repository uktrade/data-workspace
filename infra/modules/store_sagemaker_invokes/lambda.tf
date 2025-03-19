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
    resources = [var.sns_success_topic_arn, var.sns_error_topic_arn]
  }
  statement {
    actions   = ["rds-db:connect", "rds-data:ExecuteStatement", "rds-data:ExecuteSql", "rds-data:BatchExecuteStatement", "rds-data:BeginTransaction", "rds-data:CommitTransaction", "rds-data:RollbackTransaction"]
    resources = [aws_rds_cluster.sagemaker.arn]
  }
  statement {
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents", "logs:DescribeLogStreams"]
    resources = ["arn:aws:logs:*:*:*"]
  }
  statement {
    actions   = ["secretsmanager:GetSecretValue", "secretsmanager:ListSecrets", "secretsmanager:GetRandomPassword"]
    resources = [aws_secretsmanager_secret.sagemaker_db.arn]
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
  environment {
    variables = {
      SAGEMAKER_DB_ARN        = aws_rds_cluster.sagemaker.arn
      SAGEMAKER_DB_SECRET_ARN = aws_secretsmanager_secret.sagemaker_db.arn
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
  statement_id  = "AllowExecutionFromSNS-success-store"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_sns_to_rds.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = var.sns_success_topic_arn
}

resource "aws_lambda_permission" "error_with_sns" {
  statement_id  = "AllowExecutionFromSNS-error-store"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_sns_to_rds.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = var.sns_error_topic_arn
}

data "aws_iam_policy_document" "sns_publish_and_read_policy_success_store" {
  statement {
    sid     = "sns_publish_and_read_policy_success_store_1"
    actions = ["SNS:Publish"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["sagemaker.amazonaws.com"]
    }
    resources = [var.sns_success_topic_arn]
  }
  statement {
    sid     = "sns_publish_and_read_policy_success_store_2"
    actions = ["SNS:Receive", "SNS:Subscribe"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    resources = [var.sns_success_topic_arn]
  }
}

data "aws_iam_policy_document" "sns_publish_and_read_policy_error_store" {
  statement {
    sid     = "sns_publish_and_read_policy_error_store_1"
    actions = ["SNS:Publish"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["sagemaker.amazonaws.com"]
    }
    resources = [var.sns_error_topic_arn]
  }
  statement {
    sid     = "sns_publish_and_read_policy_error_store_2"
    actions = ["SNS:Receive", "SNS:Subscribe"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    resources = [var.sns_error_topic_arn]
  }
}
