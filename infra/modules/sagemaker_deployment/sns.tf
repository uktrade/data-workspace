resource "aws_sns_topic" "alarmstate" {

  name = "alarm-alarmstate-${aws_sagemaker_endpoint.main.name}"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        },
        Action   = "sns:Publish",
        Resource = "*"
      }
    ]
  })
}


resource "aws_sns_topic" "okstate" {

  name = "alarm-okstate-${aws_sagemaker_endpoint.main.name}"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        },
        Action   = "sns:Publish",
        Resource = "*"
      }
    ]
  })
}


resource "aws_sns_topic_subscription" "sns_lambda_subscription_okstate" {

  topic_arn = aws_sns_topic.okstate.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.slack_alert_function.arn
}


resource "aws_sns_topic_subscription" "sns_lambda_subscription_alarmstate" {

  topic_arn = aws_sns_topic.alarmstate.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.slack_alert_function.arn
}
