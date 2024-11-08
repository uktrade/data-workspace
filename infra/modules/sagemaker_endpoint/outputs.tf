output "endpoint_name" {
  description = "The name of the SageMaker endpoint"
  value       = aws_sagemaker_endpoint.sagemaker_endpoint.name
}

output "endpoint_config_name" {
  description = "The name of the SageMaker endpoint configuration"
  value       = aws_sagemaker_endpoint_configuration.endpoint_config.name
}

output "variant_name" {
  description = "The variant name for the SageMaker endpoint"
  value       = var.variant_name
}
