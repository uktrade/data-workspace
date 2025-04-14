# Usually Cloudwatch-related role definition are in the same files as the resources that generate
# the logs. However, in this case both the webserver and celery log to the same log groups, so
# we have the Cloudwatch resources in a separate file.

resource "aws_cloudwatch_log_group" "admin" {
  name              = "${var.prefix}-admin"
  retention_in_days = "3653"
}

resource "aws_cloudwatch_log_subscription_filter" "admin" {
  count           = var.cloudwatch_subscription_filter ? 1 : 0
  name            = "${var.prefix}-admin"
  log_group_name  = aws_cloudwatch_log_group.admin.name
  filter_pattern  = ""
  destination_arn = var.cloudwatch_destination_arn
}
