output "sns_topic_arn" {
    value = aws_sns_topic.budget_alert_topic.arn
}