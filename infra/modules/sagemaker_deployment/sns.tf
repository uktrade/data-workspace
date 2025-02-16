resource "aws_sns_topic" "scale_up_from_0_to_1_alarmstate" {

  name = "alarm-alarmstate-${aws_sagemaker_endpoint.main.name}-scale-up-from-0-to-1"
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


resource "aws_sns_topic" "scale_up_from_0_to_1_okstate" {

  name = "alarm-okstate-${aws_sagemaker_endpoint.main.name}-scale-up-from-0-to-1"

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


resource "aws_sns_topic" "scale_down_from_n_to_0_alarmstate" {

  name = "alarm-alarmstate-${aws_sagemaker_endpoint.main.name}-scale-down-from-n-to-0"
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


resource "aws_sns_topic" "scale_down_from_n_to_0_okstate" {

  name = "alarm-okstate-${aws_sagemaker_endpoint.main.name}-scale-down-from-n-to-0"

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

  topic_arn = aws_sns_topic.scale_up_from_0_to_1_okstate.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.slack_alert_function.arn
}


resource "aws_sns_topic_subscription" "sns_lambda_subscription_alarmstate" {

  topic_arn = aws_sns_topic.scale_up_from_0_to_1_alarmstate.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.slack_alert_function.arn
}
