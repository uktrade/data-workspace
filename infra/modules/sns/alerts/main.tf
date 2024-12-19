resource "aws_sns_topic" "alert_topic" {
  count = var.create ? 1 : 0

  name = var.sns_topic_name
  tags = var.tags
}

resource "aws_sns_topic_subscription" "slack_lambda_subscription" {
  count = var.enable_notifications ? 1 : 0

  topic_arn = aws_sns_topic.alert_topic[0].arn
  protocol  = "lambda"
  endpoint  = var.lambda_arn

  depends_on = [aws_lambda_permission.allow_sns]
}

resource "aws_lambda_permission" "allow_sns" {
  count = var.enable_notifications ? 1 : 0

  statement_id  = "AllowExecutionFromSNS-${var.sns_topic_name}"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.alert_topic[0].arn
}

output "sns_topic_arn" {
  value = aws_sns_topic.alert_topic[0].arn
}
