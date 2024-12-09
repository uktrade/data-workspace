
resource "aws_iam_role" "iam_for_lambda_s3_move" {
  name = "iam_for_lambda_s3_move"
  assume_role_policy =  jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }]})
}

resource "aws_iam_role_policy" "policy_for_lambda_s3_move" {
  name = "policy_for_lambda_s3_move"
  role = aws_iam_role.iam_for_lambda_s3_move.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["SNS:Receive", "SNS:Subscribe"]
        Effect   = "Allow"
        Resource = aws_sns_topic.async-sagemaker-success-topic.arn
      },
      {
        Action   = ["s3:GetObject"]
        Effect   = "Allow"
        Resource = "arn:aws:s3:::*sagemaker*"
      },
      {
        Action   = ["s3:PutObject"]
        Effect   = "Allow"
        Resource = "${var.s3_bucket_notebooks_arn}*"
      }
    ]
  })
}

data "archive_file" "lambda_payload" {
  type        = "zip"
  source_file = "${path.module}/lambda_function/s3_move_output.py"
  output_path = "${path.module}/lambda_function/payload.zip"
}

resource "aws_lambda_function" "lambda_s3_move_output" {
  filename      = data.archive_file.lambda_payload.output_path
  source_code_hash = data.archive_file.lambda_payload.output_base64sha256
  function_name = "lambda_s3_move_output"
  role          = aws_iam_role.iam_for_lambda_s3_move.arn
  handler       = "s3_move_output.lambda_handler"
  runtime       = "python3.12"
  timeout       = 30
  }


resource "aws_sns_topic" "async-sagemaker-success-topic" {
  name = "async-sagemaker-success-topic"
  policy = data.aws_iam_policy_document.sns_publish_and_read_policy.json
}

resource "aws_sns_topic_subscription" "topic_lambda" {
  topic_arn = aws_sns_topic.async-sagemaker-success-topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.lambda_s3_move_output.arn
}

resource "aws_lambda_permission" "with_sns" {
    statement_id = "AllowExecutionFromSNS"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.lambda_s3_move_output.function_name
    principal = "sns.amazonaws.com"
    source_arn = aws_sns_topic.async-sagemaker-success-topic.arn
}

data "aws_iam_policy_document" "sns_publish_and_read_policy" {
    statement {
        sid = "sns_publish_and_read_policy_1"
        actions = ["SNS:Publish"]
        effect = "Allow"
        principals {
          type = "Service"
          identifiers = ["sagemaker.amazonaws.com"]
        }
        resources = ["arn:aws:sns:${var.aws_region}:${var.account_id}:async-sagemaker-success-topic"]
    }
    statement {
        sid = "sns_publish_and_read_policy_2"
        actions = ["SNS:Receive","SNS:Subscribe"]
        effect = "Allow"
        principals {
            type = "Service"
            identifiers = ["lambda.amazonaws.com"]
        }
        resources = ["arn:aws:sns:${var.aws_region}:${var.account_id}:async-sagemaker-success-topic"]
    }
}
