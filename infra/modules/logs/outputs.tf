output "subscription_filter_name" {
    value = aws_cloudwatch_log_subscription_filter.sagemaker_logs.name
}


output "sagemaker_log_group_arn" {
  value       = data.aws_cloudwatch_log_group.sagemaker_logs.arn
  description = "The ARN of the CloudWatch log group for SageMaker"
}