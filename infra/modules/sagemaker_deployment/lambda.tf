data "archive_file" "lambda_payload" {
  type        = "zip"
  source_file = "${path.module}/lambda_function/sns_to_microsoft_teams.py"
  output_path = "${path.module}/lambda_function/payload.zip"
}


resource "aws_sns_topic_subscription" "sns_lambda_subscription_scale_up_from_0_to_1" {

  topic_arn = aws_sns_topic.scale_up_from_0_to_1.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.teams_alert.arn
}


resource "aws_sns_topic_subscription" "sns_lambda_subscription_scale_up_from_n_to_np1" {

  topic_arn = aws_sns_topic.scale_up_from_n_to_np1.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.teams_alert.arn
}


resource "aws_sns_topic_subscription" "sns_lambda_subscription_scale_down_from_n_to_nm1" {

  topic_arn = aws_sns_topic.scale_down_from_n_to_nm1.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.teams_alert.arn
}


resource "aws_sns_topic_subscription" "sns_lambda_subscription_scale_down_from_n_to_0" {

  topic_arn = aws_sns_topic.scale_down_from_n_to_0.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.teams_alert.arn
}


resource "aws_lambda_function" "teams_alert" {
  filename         = data.archive_file.lambda_payload.output_path
  source_code_hash = data.archive_file.lambda_payload.output_base64sha256
  function_name    = "${aws_sagemaker_model.main.name}-teams-alert"
  role             = aws_iam_role.teams_lambda.arn
  handler          = "sns_to_microsoft_teams.lambda_handler"
  runtime          = "python3.12"
  timeout          = 30
  environment {
    variables = {
      TEAMS_WEBHOOK_URL = var.teams_webhook_url
    }
  }
}


resource "aws_lambda_permission" "allow_sns_scale_up_from_0_to_1" {

  statement_id  = "AllowSNS-scale-up-from-0-to-1"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.teams_alert.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.scale_up_from_0_to_1.arn
}



resource "aws_lambda_permission" "allow_sns_scale_down_from_n_to_nm1" {

  statement_id  = "AllowSNS-scale-down-from-n-to-nm1"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.teams_alert.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.scale_down_from_n_to_nm1.arn

}


resource "aws_iam_role" "teams_lambda" {
  name = "${aws_sagemaker_model.main.name}-teams-lambda-role"

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


resource "aws_iam_policy" "teams_lambda" {
  name = "${aws_sagemaker_model.main.name}-teams-lambda-policy"

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


resource "aws_iam_role_policy_attachment" "teams_lambda" {
  role       = aws_iam_role.teams_lambda.name
  policy_arn = aws_iam_policy.teams_lambda.arn
}
