resource "aws_cloudwatch_metric_alarm" "cloudwatch_alarm" {
  count = length(var.alarms)

  alarm_name          = "${var.alarms[count.index].alarm_name_prefix}-${aws_sagemaker_endpoint.main.name}"
  alarm_description   = var.alarms[count.index].alarm_description
  metric_name         = var.alarms[count.index].metric_name
  namespace           = var.alarms[count.index].namespace
  comparison_operator = var.alarms[count.index].comparison_operator
  threshold           = var.alarms[count.index].threshold
  evaluation_periods  = var.alarms[count.index].evaluation_periods
  datapoints_to_alarm = var.alarms[count.index].datapoints_to_alarm
  period              = var.alarms[count.index].period
  statistic           = var.alarms[count.index].statistic
  alarm_actions       = concat(var.alarms[count.index].alarm_actions, [aws_sns_topic.sns_topic_alarmstate[count.index].arn])
  ok_actions          = concat(var.alarms[count.index].ok_actions, [aws_sns_topic.sns_topic_okstate[count.index].arn])
  dimensions = (count.index == 0 || count.index == 1 || count.index == 2) ? { # TODO: this logic is brittle as it assumes "backlog" has index [0,1,2]; it would be better to have a logic that rests on the specific name of that metric
    EndpointName = aws_sagemaker_endpoint.main.name             # Only EndpointName is used in this case
    } : {
    EndpointName = aws_sagemaker_endpoint.main.name,                                          # Both EndpointName and VariantName are used in all other cases
    VariantName  = aws_sagemaker_endpoint_configuration.main.production_variants[0].variant_name # Note this logic would not work if there were ever more than one production variant deployed for an LLM
  }

  depends_on = [aws_sagemaker_endpoint.main, aws_sns_topic.sns_topic_alarmstate, aws_sns_topic.sns_topic_okstate]
}


resource "null_resource" "wait_for_metric_alarms" {
  #  Aggregating metric alarms dependencies so we wait for them to be deleted/created before composite alarms are created or deleted. This prevents cyclic dependency issues.
  depends_on = [aws_cloudwatch_metric_alarm.cloudwatch_alarm]
}


resource "aws_cloudwatch_composite_alarm" "composite_alarm" {
  count = length(var.alarm_composites)

  alarm_name        = "${var.alarm_composites[count.index].alarm_name}-${aws_sagemaker_endpoint.main.name}"
  alarm_description = var.alarm_composites[count.index].alarm_description
  alarm_rule        = var.alarm_composites[count.index].alarm_rule
  alarm_actions     = concat(var.alarm_composites[count.index].alarm_actions, [aws_sns_topic.alarm_composite_notifications[count.index].arn], [aws_sns_topic.sns_topic_composite[count.index].arn])
  ok_actions        = var.alarm_composites[count.index].ok_actions

  depends_on = [aws_sagemaker_endpoint.main, aws_sns_topic.alarm_composite_notifications, aws_sns_topic.sns_topic_composite, null_resource.wait_for_metric_alarms]

}
