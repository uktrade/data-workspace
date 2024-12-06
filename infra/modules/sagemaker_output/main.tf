resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
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

resource "aws_iam_role_policy" "policy_for_lambda" {
  name = "test_policy"
  role = aws_iam_role.iam_for_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "SNS:Subscribe",
          "SNS:SetTopicAttributes",
          "SNS:RemovePermission",
          "SNS:Receive",
          "SNS:Publish",
          "SNS:ListSubscriptionsByTopic",
          "SNS:GetTopicAttributes",
          "SNS:DeleteTopic",
          "SNS:AddPermission",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

data "archive_file" "lambda_payload" {
  type        = "zip"
  source_file = "lambda_function/s3_move_output.py"
  output_path = "lambda_function/payload.zip"
}

resource "aws_lambda_function" "lambda_s3_move_output" {
  filename      = data.archive_file.lambda_payload.output_path
  source_code_hash = data.archive_file.lambda_payload.output_base64sha256
  function_name = "lambda_s3_move_output"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "s3_move_output.lambda_handler"
  runtime = "python3.12"
  }
