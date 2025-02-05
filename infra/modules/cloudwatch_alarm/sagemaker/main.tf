resource "aws_cloudwatch_metric_alarm" "sagemaker_alarm" {
  alarm_name          = var.alarm_name
  alarm_description   = var.alarm_description
  metric_name         = var.metric_name
  namespace           = var.namespace
  comparison_operator = var.comparison_operator
  threshold           = var.threshold
  evaluation_periods  = var.evaluation_periods
  datapoints_to_alarm = var.datapoints_to_alarm
  treat_missing_data  = "missing"
  statistic           = "Average"
  period              = var.period

  dimensions = {
    EndpointName = var.endpoint_name
    VariantName  = var.variant_name != null ? var.variant_name : ""

  }

  alarm_actions = var.alarm_actions
}
