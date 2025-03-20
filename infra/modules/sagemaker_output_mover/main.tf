resource "aws_iam_role_policy" "lambda_s3_move" {
  name   = "${var.prefix}-policy-for-lambda-s3-move"
  role   = aws_iam_role.lambda_s3_move.id
  policy = data.aws_iam_policy_document.lambda_s3_move.json
}


resource "aws_iam_role" "lambda_s3_move" {
  name = "${var.prefix}-iam-for-lambda-s3-move"
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


data "aws_iam_policy_document" "lambda_s3_move" {
  statement {
    actions   = ["SNS:Receive", "SNS:Subscribe"]
    resources = [aws_sns_topic.async_sagemaker_success_topic.arn, aws_sns_topic.async_sagemaker_error_topic.arn]
  }
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${var.default_sagemaker_bucket_arn}/*"]
  }
  statement {
    actions   = ["s3:PutObject"]
    resources = ["${var.s3_bucket_notebooks_arn}/*"]
  }
  statement {
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents", "logs:DescribeLogStreams"]
    resources = ["arn:aws:logs:*:*:*"]
  }
}


data "archive_file" "lambda_payload" {
  type        = "zip"
  source_file = "${path.module}/lambda_function/s3_move_output.py"
  output_path = "${path.module}/lambda_function/payload.zip"
}


resource "aws_lambda_function" "lambda_s3_move_output" {
  filename         = data.archive_file.lambda_payload.output_path
  source_code_hash = data.archive_file.lambda_payload.output_base64sha256
  function_name    = "${var.prefix}-s3-output-mover"
  role             = aws_iam_role.lambda_s3_move.arn
  handler          = "s3_move_output.lambda_handler"
  runtime          = "python3.12"
  timeout          = 30
  layers           = [aws_lambda_layer_version.boto3_stubs_s3.arn]
}


resource "aws_lambda_layer_version" "boto3_stubs_s3" {
  layer_name  = "boto3-stubs-s3"
  s3_bucket   = aws_s3_bucket.lambda_layers.id
  s3_key      = "boto3-stubs-s3-layer.zip"
  description = "Contains boto3-stubs[s3]"
}


resource "aws_s3_bucket" "lambda_layers" {
  bucket = "${var.prefix}-${var.aws_region}-lambda-layers"
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}


resource "aws_sns_topic" "async_sagemaker_success_topic" {
  name   = "${var.prefix}-async-sagemaker-success-topic"
  policy = data.aws_iam_policy_document.sns_publish_and_read_policy_success.json
}


resource "aws_sns_topic" "async_sagemaker_error_topic" {
  name   = "${var.prefix}-async-sagemaker-error-topic"
  policy = data.aws_iam_policy_document.sns_publish_and_read_policy_error.json
}


resource "aws_sns_topic_subscription" "error_topic_lambda" {
  topic_arn = aws_sns_topic.async_sagemaker_error_topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.lambda_s3_move_output.arn
}


resource "aws_sns_topic_subscription" "success_topic_lambda" {
  topic_arn = aws_sns_topic.async_sagemaker_success_topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.lambda_s3_move_output.arn
}


resource "aws_lambda_permission" "success_with_sns" {
  statement_id  = "AllowExecutionFromSNS-success"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_s3_move_output.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.async_sagemaker_success_topic.arn
}


resource "aws_lambda_permission" "error_with_sns" {
  statement_id  = "AllowExecutionFromSNS-error"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_s3_move_output.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.async_sagemaker_error_topic.arn
}


data "aws_iam_policy_document" "sns_publish_and_read_policy_success" {
  statement {
    sid     = "sns_publish_and_read_policy_1"
    actions = ["SNS:Publish"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["sagemaker.amazonaws.com"]
    }
    # TODO: circular dependency to get this ARN programmatically
    resources = ["arn:aws:sns:${var.aws_region}:${var.account_id}:${var.prefix}-async-sagemaker-success-topic"]
  }
  statement {
    sid     = "sns_publish_and_read_policy_2"
    actions = ["SNS:Receive", "SNS:Subscribe"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    # TODO: circular dependency to get this ARN programmatically
    resources = ["arn:aws:sns:${var.aws_region}:${var.account_id}:${var.prefix}-async-sagemaker-success-topic"]
  }
}

data "aws_iam_policy_document" "sns_publish_and_read_policy_error" {
  statement {
    sid     = "sns_publish_and_read_policy_1"
    actions = ["SNS:Publish"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["sagemaker.amazonaws.com"]
    }
    # TODO: circular dependency to get this ARN programmatically
    resources = ["arn:aws:sns:${var.aws_region}:${var.account_id}:${var.prefix}-async-sagemaker-error-topic"]
  }
  statement {
    sid     = "sns_publish_and_read_policy_2"
    actions = ["SNS:Receive", "SNS:Subscribe"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    # TODO: circular dependency to get this ARN programmatically
    resources = ["arn:aws:sns:${var.aws_region}:${var.account_id}:${var.prefix}-async-sagemaker-error-topic"]
  }
}
