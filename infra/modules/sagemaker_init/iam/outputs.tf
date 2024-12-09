output "execution_role" {
    description = "ARN of the sagemaker execution role"
    value = aws_iam_role.sagemaker.arn
}

output "inference_role" {
    description = "ARN of the sagemaker inference role"
    value = aws_iam_role.inference_role.arn
}

output "default_sagemaker_bucket" {
    description = "Default sagemaker bucket full object"
    value = aws_s3_bucket.sagemaker_default_bucket
}
