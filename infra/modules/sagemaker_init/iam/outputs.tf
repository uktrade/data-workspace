output "execution_role" {
  description = "ARN of the sagemaker execution role"
  value       = aws_iam_role.sagemaker.arn
}

output "inference_role" {
  description = "ARN of the sagemaker inference role"
  value       = aws_iam_role.inference_role.arn
}

output "default_sagemaker_bucket_regional_domain_name" {
  description = "Default sagemaker bucket regional domain name"
  value       = aws_s3_bucket.sagemaker_default_bucket.bucket_regional_domain_name
}

output "default_sagemaker_bucket_arn" {
  description = "Default sagemaker bucket arn"
  value       = aws_s3_bucket.sagemaker_default_bucket.arn
}
