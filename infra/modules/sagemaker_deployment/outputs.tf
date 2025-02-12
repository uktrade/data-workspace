output "model_name" {
  value = aws_sagemaker_model.sagemaker_model.name
}


output "endpoint_name" {
  value = aws_sagemaker_endpoint.sagemaker_endpoint.name
}


output "scale_up_to_one_policy_arn" {
  value = aws_appautoscaling_policy.scale_up_to_one_policy.arn
}


output "scale_down_to_zero_policy_arn" {
  value = aws_appautoscaling_policy.scale_down_to_zero_policy.arn
}


output "scale_up_to_n_policy_arn" {
  value = aws_appautoscaling_policy.scale_up_to_n_policy.arn
}


output "scale_down_to_n_policy_arn" {
  value = aws_appautoscaling_policy.scale_down_to_n_policy.arn
}
