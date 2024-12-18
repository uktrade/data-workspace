output "lambda_function_arn" {
  value = aws_lambda_function.sagemaker_to_s3.arn
}