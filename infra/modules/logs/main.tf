resource "aws_cloudwatch_log_group" "budget_alert_log_group" {
    name = "/aws/budget-alerts/${var.prefix}"
    retention_in_days = var.retention_in_days
}