resource "aws_sns_topic" "sns_topic_alarmstate" {
  count = length(var.alarms)

  name = "alarm-alarmstate-${var.alarms[count.index].alarm_name_prefix}-${aws_sagemaker_endpoint.sagemaker_endpoint.name}"
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


resource "aws_sns_topic" "sns_topic_okstate" {
  count = length(var.alarms)

  name = "alarm-okstate-${var.alarms[count.index].alarm_name_prefix}-${aws_sagemaker_endpoint.sagemaker_endpoint.name}"

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


resource "aws_sns_topic" "sns_topic_composite" {
  count = length(var.alarm_composites)

  name = "alarm-alarm-composite-lambda-${var.alarm_composites[count.index].alarm_name}-${aws_sagemaker_endpoint.sagemaker_endpoint.name}-topic"

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


resource "aws_sns_topic" "alarm_composite_notifications" {
  count = length(var.alarm_composites)
  name  = "alarm-composite-${var.alarm_composites[count.index].alarm_name}-${aws_sagemaker_endpoint.sagemaker_endpoint.name}-sns-topic"
}


resource "aws_sns_topic_policy" "composite_sns_topic_policy" {
  count = length(var.alarm_composites)

  arn = aws_sns_topic.alarm_composite_notifications[count.index].arn
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowPublishFromCloudWatch"
        Effect = "Allow",
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        },
        Action   = "SNS:Publish",
        Resource = aws_sns_topic.alarm_composite_notifications[count.index].arn
      },
      {
        Sid       = "AllowSubscriptionActions"
        Effect    = "Allow",
        Principal = "*",
        Action = [
          "sns:Subscribe",
          "sns:Receive"
        ],
        Resource = aws_sns_topic.alarm_composite_notifications[count.index].arn
      }
    ]
  })
}


resource "aws_sns_topic_subscription" "sns_lambda_subscription_okstate" {
  count = length(var.alarms)

  topic_arn = aws_sns_topic.sns_topic_okstate[count.index].arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.slack_alert_function.arn
}


resource "aws_sns_topic_subscription" "sns_lambda_subscription_alarmstate" {
  count = length(var.alarms)

  topic_arn = aws_sns_topic.sns_topic_alarmstate[count.index].arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.slack_alert_function.arn
}

resource "aws_sns_topic_subscription" "sns_lambda_subscription_composite" {
  count = length(var.alarm_composites)

  topic_arn = aws_sns_topic.sns_topic_composite[count.index].arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.slack_alert_function.arn
}


resource "aws_sns_topic_subscription" "email_subscription" {
  count     = length(var.alarm_composites)
  topic_arn = aws_sns_topic.alarm_composite_notifications[count.index].arn
  protocol  = "email"
  endpoint = flatten([
    for variables in var.alarm_composites :
    [
      for email in variables.emails :
      email
    ]
  ])[count.index]
}
