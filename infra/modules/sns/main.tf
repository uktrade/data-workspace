resource "aws_sns_topic" "budget_alert_topic" {
    name = "${var.prefix}-budget-alert-topic"
    policy = data.aws_iam_policy_document.budget_publish_policy.json
}

resource "aws_sns_topic" "unauthorised_access_topic" {
    name = "${var.prefix}-unauthorised-access-alert-topic"
    policy = data.aws_iam_policy_document.unauthorised_access_policy.json
}

resource "aws_sns_topic_subscription" "email_subscription" {
    topic_arn = aws_sns_topic.unauthorised_access_topic.arn
    protocol = "email"
    endpoint = var.notification_email[0]
}

data "aws_iam_policy_document" "budget_publish_policy" {
    statement {
        actions = ["SNS:Publish"]
        effect = "Allow"
        principals {
          type = "Service"
          identifiers = [ "budgets.amazonaws.com" ] 
        }
        resources = [
            "arn:aws:sns:eu-west-2:${var.account_id}:${var.prefix}-budget-alert-topic"
        ]
    }
}

data "aws_iam_policy_document" "unauthorised_access_policy" {
    statement {
        actions = ["SNS:Publish"]
        effect = "Allow"
        principals {
          type = "Service"
          identifiers = [ "cloudwatch.amazonaws.com" ] 
        }
        resources = [
            "arn:aws:sns:eu-west-2:${var.account_id}:${var.prefix}-unauthorised-access-alert-topic"
        ]
    }
}

