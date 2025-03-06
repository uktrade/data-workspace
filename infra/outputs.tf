output "model_name" {
  value = module.sagemaker_deployment[0].aws_sagemaker_model.main.name
}
