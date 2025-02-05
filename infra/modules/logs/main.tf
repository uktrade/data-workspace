resource "aws_cloudwatch_log_group" "budget_alert_log_group" {
  name              = "/aws/budget-alerts/${var.prefix}"
  retention_in_days = var.retention_in_days
}

data "aws_cloudwatch_log_group" "sagemaker_logs" {
  for_each = toset(var.endpoint_names)
  name     = "/aws/sagemaker/Endpoints/${each.key}"
}

resource "aws_cloudwatch_log_subscription_filter" "sagemaker_logs" {
  for_each        = toset(var.endpoint_names)
  name            = "sagemaker-log-filter-${each.key}"
  log_group_name  = data.aws_cloudwatch_log_group.sagemaker_logs[each.key].name
  destination_arn = var.lambda_function_arn
  filter_pattern  = ""
}
