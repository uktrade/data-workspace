output "sns_topic_arn" {
  value = aws_sns_topic.budget_alert_topic.arn
}

output "unauthorised_access_sns_topic_arn" {
  value = aws_sns_topic.unauthorised_access_topic.arn
}