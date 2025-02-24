
output "sagemaker_log_group_arns" {
  value = {
    for key, group in data.aws_cloudwatch_log_group.sagemaker_logs :
    key => group.arn
  }
  description = "Map of log group ARNs by endpoint"
}
