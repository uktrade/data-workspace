output "sns_error_topic_arn" {
  value = aws_sns_topic.async-sagemaker-error-topic
}

output "sns_success_topic_arn" {
  value = aws_sns_topic.async-sagemaker-success-topic
}
