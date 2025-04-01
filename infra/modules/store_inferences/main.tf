resource "aws_iam_role" "lambda_sns_to_s3" {
  name = "${var.prefix}-iam-for-lambda-sns-to-s3"
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


resource "aws_iam_role_policy" "lambda_sns_to_s3" {
  name   = "${var.prefix}-policy-for-lambda-sns-to-s3"
  role   = aws_iam_role.lambda_sns_to_s3.id
  policy = data.aws_iam_policy_document.lambda_sns_to_s3.json
}


data "aws_iam_policy_document" "lambda_sns_to_s3" {
  statement {
    actions   = ["SNS:Receive", "SNS:Subscribe"]
    effect    = "Allow"
    resources = [var.sns_success_topic_arn, var.sns_error_topic_arn]
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
    actions   = ["s3:PutObject", "s3:GetObject"]
    effect    = "Allow"
    resources = ["${aws_s3_bucket.store_inferences.arn}/*"]
  }
}


data "archive_file" "lambda_payload" {
  type        = "zip"
  source_file = "${path.module}/lambda_function/sns_to_s3.py"
  output_path = "${path.module}/lambda_function/payload.zip"
}


resource "aws_lambda_function" "lambda_sns_to_s3" {
  filename         = data.archive_file.lambda_payload.output_path
  source_code_hash = data.archive_file.lambda_payload.output_base64sha256
  function_name    = "${var.prefix}-sns-to-s3"
  role             = aws_iam_role.lambda_sns_to_s3.arn
  handler          = "sns_to_s3.lambda_handler"
  runtime          = "python3.12"
  timeout          = 60
  environment {
    variables = {
      S3_BUCKET_NAME = aws_s3_bucket.store_inferences.id
      S3_OBJECT_KEY  = "db.csv"
    }
  }
}

resource "aws_sns_topic_subscription" "success_topic_lambda" {
  topic_arn = var.sns_success_topic_arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.lambda_sns_to_s3.arn
}


resource "aws_sns_topic_subscription" "error_topic_lambda" {
  topic_arn = var.sns_error_topic_arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.lambda_sns_to_s3.arn
}


resource "aws_lambda_permission" "success_with_sns" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_sns_to_s3.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = var.sns_success_topic_arn
}


resource "aws_lambda_permission" "error_with_sns" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_sns_to_s3.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = var.sns_error_topic_arn
}


resource "aws_s3_bucket" "store_inferences" {
  bucket = "${var.prefix}-store-sagemaker-inferences"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}
