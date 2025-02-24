resource "aws_cloudwatch_log_group" "budget_alert_log_group" {
  name              = "/aws/budget-alerts/${var.prefix}"
  retention_in_days = var.retention_in_days
}

data "aws_cloudwatch_log_group" "sagemaker_logs" {
  for_each = toset(var.endpoint_names)
  name     = "/aws/sagemaker/Endpoints/${each.key}"
}
