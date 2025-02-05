output "model_name" {
  description = "The name of the SageMaker model"
  value       = aws_sagemaker_model.sagemaker_model.name
}

output "model_arn" {
  description = "The ARN of the SageMaker model"
  value       = aws_sagemaker_model.sagemaker_model.arn
}
