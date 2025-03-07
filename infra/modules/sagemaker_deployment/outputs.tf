output "model_name" {
  value = aws_sagemaker_model.main.name
}


output "endpoint_name" {
  value = aws_sagemaker_endpoint.main.name
}
