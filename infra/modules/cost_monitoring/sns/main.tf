resource "aws_sns_topic" "budget_alert_topic" {
  name   = "${var.prefix}-budget-alert-topic"
  policy = data.aws_iam_policy_document.budget_publish_policy.json
}

data "aws_iam_policy_document" "budget_publish_policy" {
  statement {
    actions = ["SNS:Publish"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["budgets.amazonaws.com"]
    }
    resources = [
      "arn:aws:sns:eu-west-2:${var.account_id}:${var.prefix}-budget-alert-topic"
    ]
  }
}
