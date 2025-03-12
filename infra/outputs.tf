output "model_name" {
  value = module.sagemaker_deployment[0].aws_sagemaker_model.main.name
}

output "aws_iam_policy_notebook_task_execution_arn" {
  value = aws_iam_policy.notebook_task_execution.arn
}
