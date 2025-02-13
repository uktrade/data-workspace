data "archive_file" "lambda_payload" {
  type        = "zip"
  source_file = "${path.module}/lambda_function/cloudwatch_alarms_to_slack_alerts.py"
  output_path = "${path.module}/lambda_function/payload.zip"
}


resource "aws_lambda_function" "slack_alert_function" {
  filename         = data.archive_file.lambda_payload.output_path
  source_code_hash = data.archive_file.lambda_payload.output_base64sha256
  function_name    = "${var.model_name}-slack-alert-lambda"
  role             = aws_iam_role.slack_lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  timeout          = 30

}


resource "aws_lambda_permission" "allow_sns_okstate" {

  statement_id  = "AllowSNS-ok"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.slack_alert_function.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.okstate.arn
}


resource "aws_lambda_permission" "allow_sns_alarmstate" {

  statement_id  = "AllowSNS-alarm"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.slack_alert_function.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.alarmstate.arn
}


resource "aws_iam_role" "slack_lambda_role" {
  name = "${var.model_name}-slack-alert-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}


resource "aws_iam_policy" "slack_lambda_policy" {
  name = "${var.model_name}-slack-alert-lambda-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect   = "Allow",
        Action   = "sns:Publish",
        Resource = "*"
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "slack_lambda_policy_attachment" {
  role       = aws_iam_role.slack_lambda_role.name
  policy_arn = aws_iam_policy.slack_lambda_policy.arn
}
