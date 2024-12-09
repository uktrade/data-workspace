output "model_name" {
  value = aws_sagemaker_model.sagemaker_model.name
}

output "endpoint_name" {
  value = aws_sagemaker_endpoint.sagemaker_endpoint.name
}

output "scale_up_policy_arn" {
  value = aws_appautoscaling_policy.scale_up_policy.arn
}

output "scale_in_to_zero_policy_arn" {
  value = aws_appautoscaling_policy.scale_in_to_zero_policy.arn
}

output "scale_in_to_zero_based_on_backlog_arn" {
  description = "ARN of the autoscaling policy to scale in to zero for backlog queries when 0 for x minutes"
  value = aws_appautoscaling_policy.scale_in_to_zero_based_on_backlog.arn
}

