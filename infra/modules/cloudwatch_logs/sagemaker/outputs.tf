output "subscription_filter_names" {
  value = {
    for key, filter in aws_cloudwatch_log_subscription_filter.sagemaker_logs :
    key => filter.name
  }
  description = "Map of subscription filter names by endpoint"
}


output "sagemaker_log_group_arns" {
  value = {
    for key, group in data.aws_cloudwatch_log_group.sagemaker_logs :
    key => group.arn
  }
  description = "Map of log group ARNs by endpoint"
}