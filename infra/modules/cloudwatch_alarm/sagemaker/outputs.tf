output "alarm_arn" {
  description = "The ARN of the CloudWatch alarm"
  value       = aws_cloudwatch_metric_alarm.sagemaker_alarm.arn
}
