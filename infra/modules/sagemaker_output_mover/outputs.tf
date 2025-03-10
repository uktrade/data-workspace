output "sns_success_topic_arn" {
  value = aws_sns_topic.async_sagemaker_success_topic.arn
}
