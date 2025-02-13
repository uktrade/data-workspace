resource "aws_cloudwatch_composite_alarm" "scale_up_from_n_to_np1" {
  alarm_name        = "scale_up_from_n_to_np1"
  alarm_description = "Where there exists a high backlog and a high state of any of CPU, GPU, RAM, HardDisk (i.e. live instances are insufficient for the tasks being performed)"

  alarm_actions = [aws_appautoscaling_policy.scale_up_from_n_to_np1.arn]
  ok_actions    = []

  alarm_rule = "ALARM(${aws_cloudwatch_metric_alarm.backlog_high.alarm_name}) AND (ALARM(${aws_cloudwatch_metric_alarm.cpu_high.alarm_name}) OR ALARM(${aws_cloudwatch_metric_alarm.gpu_high.alarm_name}) OR ALARM(${aws_cloudwatch_metric_alarm.ram_high.alarm_name}) OR ALARM(${aws_cloudwatch_metric_alarm.harddisk_high.alarm_name}))"
}

resource "aws_cloudwatch_composite_alarm" "scale_up_from_0_to_1" {
  alarm_name        = "scale_up_from_0_to_1"
  alarm_description = "Where there exists a high backlog and there exists a state of insufficient data for any of CPU, GPU, RAM, HardDisk (i.e. there are tasks to do but no instance is live to perform it)"

  alarm_actions = [aws_appautoscaling_policy.scale_up_from_0_to_1.arn]
  ok_actions    = []

  alarm_rule = "ALARM(${aws_cloudwatch_metric_alarm.backlog_high.alarm_name}) AND (INSUFFICIENT_DATA(${aws_cloudwatch_metric_alarm.cpu_high.alarm_name}) OR INSUFFICIENT_DATA(${aws_cloudwatch_metric_alarm.gpu_high.alarm_name}) OR INSUFFICIENT_DATA(${aws_cloudwatch_metric_alarm.ram_high.alarm_name}) OR INSUFFICIENT_DATA(${aws_cloudwatch_metric_alarm.harddisk_high.alarm_name}))"
}


resource "aws_cloudwatch_composite_alarm" "scale_down_from_n_to_nm1" {
  alarm_name        = "scale_down_from_n_to_nm1"
  alarm_description = "Where there exists a high backlog and a low state of any of CPU, GPU, RAM, HardDisk (i.e. live instances are excessive for the current tasks)"

  alarm_actions = [aws_appautoscaling_policy.scale_down_from_n_to_nm1.arn]
  ok_actions    = []

  alarm_rule = "ALARM(${aws_cloudwatch_metric_alarm.backlog_high.alarm_name}) AND (ALARM(${aws_cloudwatch_metric_alarm.cpu_low.alarm_name}) OR ALARM(${aws_cloudwatch_metric_alarm.gpu_low.alarm_name}) OR ALARM(${aws_cloudwatch_metric_alarm.ram_low.alarm_name}) OR ALARM(${aws_cloudwatch_metric_alarm.harddisk_low.alarm_name}))"
}


resource "aws_cloudwatch_composite_alarm" "scale_down_from_n_to_0" {
  alarm_name        = "example-composite-alarm"
  alarm_description = "Where there exists a low backlog and a low state of any of CPU, GPU, RAM, HardDisk (i.e. there is no task to come and live instances are excessive for any tasks currently in process)"

  alarm_actions = [aws_appautoscaling_policy.scale_down_from_n_to_0.arn]
  ok_actions    = []

  alarm_rule = "ALARM(${aws_cloudwatch_metric_alarm.backlog_low.alarm_name}) AND (ALARM(${aws_cloudwatch_metric_alarm.cpu_low.alarm_name}) OR ALARM(${aws_cloudwatch_metric_alarm.gpu_low.alarm_name}) OR ALARM(${aws_cloudwatch_metric_alarm.ram_low.alarm_name}) OR ALARM(${aws_cloudwatch_metric_alarm.harddisk_low.alarm_name}))"
}


resource "aws_cloudwatch_metric_alarm" "backlog_high" {

  alarm_name          = "${aws_sagemaker_endpoint.main.name}-backlog-high"
  alarm_description   = "Alarm when in high Backlog Usage"
  metric_name         = "ApproximateBacklogSize"
  namespace           = "AWS/SageMaker"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = var.backlog_threshold_high
  evaluation_periods  = var.evaluation_periods_high
  datapoints_to_alarm = var.datapoints_to_alarm_high
  period              = 60
  statistic           = "Maximum"
  dimensions          = { EndpointName = aws_sagemaker_endpoint.main.name }

  depends_on = [aws_sagemaker_endpoint.main, aws_sns_topic.alarmstate, aws_sns_topic.okstate]
}


resource "aws_cloudwatch_metric_alarm" "backlog_low" {

  alarm_name          = "${aws_sagemaker_endpoint.main.name}-backlog-low"
  alarm_description   = "Alarm when in low Backlog Usage"
  metric_name         = "ApproximateBacklogSize"
  namespace           = "AWS/SageMaker"
  comparison_operator = "LessThanThreshold"
  threshold           = var.backlog_threshold_low
  evaluation_periods  = var.evaluation_periods_low
  datapoints_to_alarm = var.datapoints_to_alarm_low
  period              = 60
  statistic           = "Maximum"
  dimensions          = { EndpointName = aws_sagemaker_endpoint.main.name }

  depends_on = [aws_sagemaker_endpoint.main, aws_sns_topic.alarmstate, aws_sns_topic.okstate]
}


resource "aws_cloudwatch_metric_alarm" "cpu_high" {

  alarm_name          = "${aws_sagemaker_endpoint.main.name}-cpu-high"
  alarm_description   = "Alarm when in high vCPU Usage"
  metric_name         = "CPUUtilization"
  namespace           = "/aws/sagemaker/Endpoints"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = var.cpu_threshold_high
  evaluation_periods  = var.evaluation_periods_high
  datapoints_to_alarm = var.datapoints_to_alarm_high
  period              = 60
  statistic           = "Average"
  dimensions = { EndpointName = aws_sagemaker_endpoint.main.name,
  VariantName = aws_sagemaker_endpoint_configuration.main.production_variants[0].variant_name }

  depends_on = [aws_sagemaker_endpoint.main, aws_sns_topic.alarmstate, aws_sns_topic.okstate]
}


resource "aws_cloudwatch_metric_alarm" "cpu_low" {

  alarm_name          = "${aws_sagemaker_endpoint.main.name}-cpu-low"
  alarm_description   = "Alarm when in low vCPU Usage"
  metric_name         = "CPUUtilization"
  namespace           = "/aws/sagemaker/Endpoints"
  comparison_operator = "LessThanOrEqualToThreshold"
  threshold           = var.cpu_threshold_low
  evaluation_periods  = var.evaluation_periods_low
  datapoints_to_alarm = var.datapoints_to_alarm_low
  period              = 60
  statistic           = "Average"
  dimensions = { EndpointName = aws_sagemaker_endpoint.main.name,
  VariantName = aws_sagemaker_endpoint_configuration.main.production_variants[0].variant_name }

  depends_on = [aws_sagemaker_endpoint.main, aws_sns_topic.alarmstate, aws_sns_topic.okstate]
}


resource "aws_cloudwatch_metric_alarm" "gpu_high" {

  alarm_name          = "${aws_sagemaker_endpoint.main.name}-gpu-high"
  alarm_description   = "Alarm when in high GPU Usage"
  metric_name         = "GPUUtilization"
  namespace           = "/aws/sagemaker/Endpoints"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = var.gpu_threshold_high
  evaluation_periods  = var.evaluation_periods_high
  datapoints_to_alarm = var.datapoints_to_alarm_high
  period              = 60
  statistic           = "Average"
  dimensions = { EndpointName = aws_sagemaker_endpoint.main.name,
  VariantName = aws_sagemaker_endpoint_configuration.main.production_variants[0].variant_name }

  depends_on = [aws_sagemaker_endpoint.main, aws_sns_topic.alarmstate, aws_sns_topic.okstate]
}


resource "aws_cloudwatch_metric_alarm" "gpu_low" {

  alarm_name          = "${aws_sagemaker_endpoint.main.name}-gpu-low"
  alarm_description   = "Alarm when in low GPU Usage"
  metric_name         = "GPUUtilization"
  namespace           = "/aws/sagemaker/Endpoints"
  comparison_operator = "LessThanOrEqualToThreshold"
  threshold           = var.gpu_threshold_low
  evaluation_periods  = var.evaluation_periods_low
  datapoints_to_alarm = var.datapoints_to_alarm_low
  period              = 60
  statistic           = "Average"
  dimensions = { EndpointName = aws_sagemaker_endpoint.main.name,
  VariantName = aws_sagemaker_endpoint_configuration.main.production_variants[0].variant_name }

  depends_on = [aws_sagemaker_endpoint.main, aws_sns_topic.alarmstate, aws_sns_topic.okstate]
}


resource "aws_cloudwatch_metric_alarm" "ram_high" {

  alarm_name          = "${aws_sagemaker_endpoint.main.name}-ram-high"
  alarm_description   = "Alarm when in high RAM Usage"
  metric_name         = "MemoryUtilization"
  namespace           = "/aws/sagemaker/Endpoints"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = var.ram_threshold_high
  evaluation_periods  = var.evaluation_periods_high
  datapoints_to_alarm = var.datapoints_to_alarm_high
  period              = 60
  statistic           = "Average"
  dimensions = { EndpointName = aws_sagemaker_endpoint.main.name,
  VariantName = aws_sagemaker_endpoint_configuration.main.production_variants[0].variant_name }

  depends_on = [aws_sagemaker_endpoint.main, aws_sns_topic.alarmstate, aws_sns_topic.okstate]
}


resource "aws_cloudwatch_metric_alarm" "ram_low" {

  alarm_name          = "${aws_sagemaker_endpoint.main.name}-ram-low"
  alarm_description   = "Alarm when in low RAM Usage"
  metric_name         = "MemoryUtilization"
  namespace           = "/aws/sagemaker/Endpoints"
  comparison_operator = "LessThanOrEqualToThreshold"
  threshold           = var.ram_threshold_low
  evaluation_periods  = var.evaluation_periods_low
  datapoints_to_alarm = var.datapoints_to_alarm_low
  period              = 60
  statistic           = "Average"
  dimensions = { EndpointName = aws_sagemaker_endpoint.main.name,
  VariantName = aws_sagemaker_endpoint_configuration.main.production_variants[0].variant_name }

  depends_on = [aws_sagemaker_endpoint.main, aws_sns_topic.alarmstate, aws_sns_topic.okstate]
}


resource "aws_cloudwatch_metric_alarm" "harddisk_high" {

  alarm_name          = "${aws_sagemaker_endpoint.main.name}-harddisk-high"
  alarm_description   = "Alarm when in high HardDisk Usage"
  metric_name         = "DiskUtilization"
  namespace           = "/aws/sagemaker/Endpoints"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = var.harddisk_threshold_high
  evaluation_periods  = var.evaluation_periods_high
  datapoints_to_alarm = var.datapoints_to_alarm_high
  period              = 60
  statistic           = "Average"
  dimensions = { EndpointName = aws_sagemaker_endpoint.main.name,
  VariantName = aws_sagemaker_endpoint_configuration.main.production_variants[0].variant_name }

  depends_on = [aws_sagemaker_endpoint.main, aws_sns_topic.alarmstate, aws_sns_topic.okstate]
}


resource "aws_cloudwatch_metric_alarm" "harddisk_low" {

  alarm_name          = "${aws_sagemaker_endpoint.main.name}-harddisk-low"
  alarm_description   = "Alarm when in low RAM Usage"
  metric_name         = "MemoryUtilization"
  namespace           = "/aws/sagemaker/Endpoints"
  comparison_operator = "LessThanOrEqualToThreshold"
  threshold           = var.ram_threshold_low
  evaluation_periods  = var.evaluation_periods_low
  datapoints_to_alarm = var.datapoints_to_alarm_low
  period              = 60
  statistic           = "Average"
  dimensions = { EndpointName = aws_sagemaker_endpoint.main.name,
  VariantName = aws_sagemaker_endpoint_configuration.main.production_variants[0].variant_name }

  depends_on = [aws_sagemaker_endpoint.main, aws_sns_topic.alarmstate, aws_sns_topic.okstate]
}


resource "aws_cloudwatch_metric_alarm" "unauthorized_operations" {

  alarm_name          = "${aws_sagemaker_endpoint.main.name}-unauthorized-operations"
  alarm_description   = "Alarm when unauthorized operations are detected in the CloudTrail Logs"
  metric_name         = "UnauthorizedOperationsCount"
  namespace           = "CloudTrailMetrics"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 1
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  period              = 60
  statistic           = "Maximum"
  dimensions = { EndpointName = aws_sagemaker_endpoint.main.name,
  VariantName = aws_sagemaker_endpoint_configuration.main.production_variants[0].variant_name }

  depends_on = [aws_sagemaker_endpoint.main, aws_sns_topic.alarmstate, aws_sns_topic.okstate]
}


resource "aws_cloudwatch_metric_alarm" "errors_4xx" {

  alarm_name          = "${aws_sagemaker_endpoint.main.name}-errors-4XX"
  alarm_description   = "4XX errors are detected in the CloudTrail Logs"
  metric_name         = "Invocation4XXErrors"
  namespace           = "AWS/SageMaker"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 1
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  period              = 60
  statistic           = "Average"
  dimensions = { EndpointName = aws_sagemaker_endpoint.main.name,
  VariantName = aws_sagemaker_endpoint_configuration.main.production_variants[0].variant_name }

  depends_on = [aws_sagemaker_endpoint.main, aws_sns_topic.alarmstate, aws_sns_topic.okstate]
}
