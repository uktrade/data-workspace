data "archive_file" "lambda_payload" {
  type        = "zip"
  source_file = "${path.module}/lambda_function.py"
  output_path = "${path.module}/payload.zip"
}

resource "aws_lambda_function" "sagemaker_to_s3" {
  filename         = data.archive_file.lambda_payload.output_path
  source_code_hash = data.archive_file.lambda_payload.output_base64sha256
  function_name    = "sagemaker-logs-to-s3"
  role             = var.log_delivery_role_arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"

  environment {
    variables = {
      S3_BUCKET_NAME = var.s3_bucket_name
    }
  }
}

resource "aws_lambda_permission" "allow_cloudwatch_logs" {
  for_each = toset(var.sagemaker_log_group_arns)

  # The statement_id must be unique, alphanumeric, and concise (max 100 characters)
  # so to ensure uniqueness and comply with AWS constraints, we use a md5 function to
  # generate a hash from the log group ARN - the hash is truncated to the first
  # 12 characters for brevity while maintaining uniqueness.
  statement_id  = "AllowExec-${substr(md5(each.key), 0, 12)}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sagemaker_to_s3.function_name
  principal     = "logs.eu-west-2.amazonaws.com"
  source_arn    = each.key
}
