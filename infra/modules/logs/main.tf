resource "aws_cloudwatch_log_group" "budget_alert_log_group" {
    name = "/aws/budget-alerts/${var.prefix}"
    retention_in_days = var.retention_in_days
}

data "aws_cloudwatch_log_group" "sagemaker_logs" {
  name = var.sagemaker_log_group
}

resource "aws_cloudwatch_log_subscription_filter" "sagemaker_logs" {
    name = "sagemaker-log-filter"
    log_group_name = data.aws_cloudwatch_log_group.sagemaker_logs.name
    destination_arn = var.lambda_function_arn
    filter_pattern = ""
}