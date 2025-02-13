
resource "aws_budgets_budget" "monthly_cost_budget" {
  name         = "${var.budget_name}-monthly-cost-budget"
  budget_type  = "COST"
  limit_amount = var.budget_limit
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  cost_filter {
    values = [var.cost_filter_service]
    name   = "Service"
  }

  notification {
    notification_type   = "ACTUAL"
    threshold_type      = "PERCENTAGE"
    comparison_operator = "GREATER_THAN"
    threshold           = 80

    subscriber_email_addresses = var.notification_email # Secrets to be passed
    subscriber_sns_topic_arns  = [var.sns_topic_arn]
  }

  notification {
    notification_type   = "ACTUAL"
    threshold_type      = "PERCENTAGE"
    comparison_operator = "GREATER_THAN"
    threshold           = 100

    subscriber_email_addresses = var.notification_email # Secrets to be passed
    subscriber_sns_topic_arns  = [var.sns_topic_arn]
  }
}



