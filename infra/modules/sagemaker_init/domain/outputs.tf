output "sagemaker_domain_id" {
  description = "The ID of the SageMaker Domain"
  value       = aws_sagemaker_domain.sagemaker.id
}