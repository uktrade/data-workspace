resource "aws_cloudwatch_metric_alarm" "backlog_high" {

  alarm_name          = "backlog-high-${aws_sagemaker_endpoint.main.name}"
  alarm_description   = "Alarm when in high Backlog Usage"
  metric_name         = "ApproximateBacklogSize"
  namespace           = "AWS/SageMaker"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = var.backlog_threshold_high
  evaluation_periods  = var.evaluation_periods_high
  datapoints_to_alarm = var.datapoints_to_alarm_high
  period              = 60
  statistic           = "Maximum"
  alarm_actions       = [aws_sns_topic.alarmstate.arn]
  ok_actions          = [aws_sns_topic.okstate.arn]
  dimensions          = { EndpointName = aws_sagemaker_endpoint.main.name }

  depends_on = [aws_sagemaker_endpoint.main, aws_sns_topic.alarmstate, aws_sns_topic.okstate]
}


resource "aws_cloudwatch_metric_alarm" "backlog_low" {

  alarm_name          = "backlog-low-${aws_sagemaker_endpoint.main.name}"
  alarm_description   = "Alarm when in low Backlog Usage"
  metric_name         = "ApproximateBacklogSize"
  namespace           = "AWS/SageMaker"
  comparison_operator = "LessThanThreshold"
  threshold           = var.backlog_threshold_low
  evaluation_periods  = var.evaluation_periods_low
  datapoints_to_alarm = var.datapoints_to_alarm_low
  period              = 60
  statistic           = "Maximum"
  alarm_actions       = [aws_sns_topic.alarmstate.arn]
  ok_actions          = [aws_sns_topic.okstate.arn]
  dimensions          = { EndpointName = aws_sagemaker_endpoint.main.name }

  depends_on = [aws_sagemaker_endpoint.main, aws_sns_topic.alarmstate, aws_sns_topic.okstate]
}


resource "aws_cloudwatch_metric_alarm" "cpu_high" {

  alarm_name          = "cpu-high-${aws_sagemaker_endpoint.main.name}"
  alarm_description   = "Alarm when in high vCPU Usage"
  metric_name         = "CPUUtilization"
  namespace           = "/aws/sagemaker/Endpoints"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = var.cpu_threshold_high
  evaluation_periods  = var.evaluation_periods_high
  datapoints_to_alarm = var.datapoints_to_alarm_high
  period              = 60
  statistic           = "Average"
  alarm_actions       = [aws_sns_topic.alarmstate.arn]
  ok_actions          = [aws_sns_topic.okstate.arn]
  dimensions = { EndpointName = aws_sagemaker_endpoint.main.name,
  VariantName = aws_sagemaker_endpoint_configuration.main.production_variants[0].variant_name }

  depends_on = [aws_sagemaker_endpoint.main, aws_sns_topic.alarmstate, aws_sns_topic.okstate]
}


resource "aws_cloudwatch_metric_alarm" "cpu_low" {

  alarm_name          = "cpu-low-${aws_sagemaker_endpoint.main.name}"
  alarm_description   = "Alarm when in low vCPU Usage"
  metric_name         = "CPUUtilization"
  namespace           = "/aws/sagemaker/Endpoints"
  comparison_operator = "LessThanOrEqualToThreshold"
  threshold           = var.cpu_threshold_low
  evaluation_periods  = var.evaluation_periods_low
  datapoints_to_alarm = var.datapoints_to_alarm_low
  period              = 60
  statistic           = "Average"
  alarm_actions       = [aws_sns_topic.alarmstate.arn]
  ok_actions          = [aws_sns_topic.okstate.arn]
  dimensions = { EndpointName = aws_sagemaker_endpoint.main.name,
  VariantName = aws_sagemaker_endpoint_configuration.main.production_variants[0].variant_name }

  depends_on = [aws_sagemaker_endpoint.main, aws_sns_topic.alarmstate, aws_sns_topic.okstate]
}


resource "aws_cloudwatch_metric_alarm" "gpu_high" {

  alarm_name          = "gpu-high-${aws_sagemaker_endpoint.main.name}"
  alarm_description   = "Alarm when in high GPU Usage"
  metric_name         = "GPUUtilization"
  namespace           = "/aws/sagemaker/Endpoints"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = var.gpu_threshold_high
  evaluation_periods  = var.evaluation_periods_high
  datapoints_to_alarm = var.datapoints_to_alarm_high
  period              = 60
  statistic           = "Average"
  alarm_actions       = [aws_sns_topic.alarmstate.arn]
  ok_actions          = [aws_sns_topic.okstate.arn]
  dimensions = { EndpointName = aws_sagemaker_endpoint.main.name,
  VariantName = aws_sagemaker_endpoint_configuration.main.production_variants[0].variant_name }

  depends_on = [aws_sagemaker_endpoint.main, aws_sns_topic.alarmstate, aws_sns_topic.okstate]
}


resource "aws_cloudwatch_metric_alarm" "gpu_low" {

  alarm_name          = "gpu-low-${aws_sagemaker_endpoint.main.name}"
  alarm_description   = "Alarm when in low GPU Usage"
  metric_name         = "GPUUtilization"
  namespace           = "/aws/sagemaker/Endpoints"
  comparison_operator = "LessThanOrEqualToThreshold"
  threshold           = var.gpu_threshold_low
  evaluation_periods  = var.evaluation_periods_low
  datapoints_to_alarm = var.datapoints_to_alarm_low
  period              = 60
  statistic           = "Average"
  alarm_actions       = [aws_sns_topic.alarmstate.arn]
  ok_actions          = [aws_sns_topic.okstate.arn]
  dimensions = { EndpointName = aws_sagemaker_endpoint.main.name,
  VariantName = aws_sagemaker_endpoint_configuration.main.production_variants[0].variant_name }

  depends_on = [aws_sagemaker_endpoint.main, aws_sns_topic.alarmstate, aws_sns_topic.okstate]
}


resource "aws_cloudwatch_metric_alarm" "ram_high" {

  alarm_name          = "ram-high-${aws_sagemaker_endpoint.main.name}"
  alarm_description   = "Alarm when in high RAM Usage"
  metric_name         = "MemoryUtilization"
  namespace           = "/aws/sagemaker/Endpoints"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = var.ram_threshold_high
  evaluation_periods  = var.evaluation_periods_high
  datapoints_to_alarm = var.datapoints_to_alarm_high
  period              = 60
  statistic           = "Average"
  alarm_actions       = [aws_sns_topic.alarmstate.arn]
  ok_actions          = [aws_sns_topic.okstate.arn]
  dimensions = { EndpointName = aws_sagemaker_endpoint.main.name,
  VariantName = aws_sagemaker_endpoint_configuration.main.production_variants[0].variant_name }

  depends_on = [aws_sagemaker_endpoint.main, aws_sns_topic.alarmstate, aws_sns_topic.okstate]
}


resource "aws_cloudwatch_metric_alarm" "ram_low" {

  alarm_name          = "ram-low-${aws_sagemaker_endpoint.main.name}"
  alarm_description   = "Alarm when in low RAM Usage"
  metric_name         = "MemoryUtilization"
  namespace           = "/aws/sagemaker/Endpoints"
  comparison_operator = "LessThanOrEqualToThreshold"
  threshold           = var.ram_threshold_low
  evaluation_periods  = var.evaluation_periods_low
  datapoints_to_alarm = var.datapoints_to_alarm_low
  period              = 60
  statistic           = "Average"
  alarm_actions       = [aws_sns_topic.alarmstate.arn]
  ok_actions          = [aws_sns_topic.okstate.arn]
  dimensions = { EndpointName = aws_sagemaker_endpoint.main.name,
  VariantName = aws_sagemaker_endpoint_configuration.main.production_variants[0].variant_name }

  depends_on = [aws_sagemaker_endpoint.main, aws_sns_topic.alarmstate, aws_sns_topic.okstate]
}


resource "aws_cloudwatch_metric_alarm" "harddisk_high" {

  alarm_name          = "harddisk-high-${aws_sagemaker_endpoint.main.name}"
  alarm_description   = "Alarm when in high HardDisk Usage"
  metric_name         = "DiskUtilization"
  namespace           = "/aws/sagemaker/Endpoints"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = var.harddisk_threshold_high
  evaluation_periods  = var.evaluation_periods_high
  datapoints_to_alarm = var.datapoints_to_alarm_high
  period              = 60
  statistic           = "Average"
  alarm_actions       = [aws_sns_topic.alarmstate.arn]
  ok_actions          = [aws_sns_topic.okstate.arn]
  dimensions = { EndpointName = aws_sagemaker_endpoint.main.name,
  VariantName = aws_sagemaker_endpoint_configuration.main.production_variants[0].variant_name }

  depends_on = [aws_sagemaker_endpoint.main, aws_sns_topic.alarmstate, aws_sns_topic.okstate]
}


resource "aws_cloudwatch_metric_alarm" "harddisk_low" {

  alarm_name          = "harddisk-low-${aws_sagemaker_endpoint.main.name}"
  alarm_description   = "Alarm when in low RAM Usage"
  metric_name         = "MemoryUtilization"
  namespace           = "/aws/sagemaker/Endpoints"
  comparison_operator = "LessThanOrEqualToThreshold"
  threshold           = var.ram_threshold_low
  evaluation_periods  = var.evaluation_periods_low
  datapoints_to_alarm = var.datapoints_to_alarm_low
  period              = 60
  statistic           = "Average"
  alarm_actions       = [aws_sns_topic.alarmstate.arn]
  ok_actions          = [aws_sns_topic.okstate.arn]
  dimensions = { EndpointName = aws_sagemaker_endpoint.main.name,
  VariantName = aws_sagemaker_endpoint_configuration.main.production_variants[0].variant_name }

  depends_on = [aws_sagemaker_endpoint.main, aws_sns_topic.alarmstate, aws_sns_topic.okstate]
}


resource "aws_cloudwatch_metric_alarm" "unauthorized_operations" {

  alarm_name          = "unauthorized-operations-${aws_sagemaker_endpoint.main.name}"
  alarm_description   = "Alarm when unauthorized operations are detected in the CloudTrail Logs"
  metric_name         = "UnauthorizedOperationsCount"
  namespace           = "CloudTrailMetrics"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 1
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  period              = 60
  statistic           = "Maximum"
  alarm_actions       = [aws_sns_topic.alarmstate.arn]
  ok_actions          = [aws_sns_topic.okstate.arn]
  dimensions = { EndpointName = aws_sagemaker_endpoint.main.name,
  VariantName = aws_sagemaker_endpoint_configuration.main.production_variants[0].variant_name }

  depends_on = [aws_sagemaker_endpoint.main, aws_sns_topic.alarmstate, aws_sns_topic.okstate]
}


resource "aws_cloudwatch_metric_alarm" "4XX-errors" {

  alarm_name          = "4XX-errors-${aws_sagemaker_endpoint.main.name}"
  alarm_description   = "4XX errors are detected in the CloudTrail Logs"
  metric_name         = "Invocation4XXErrors"
  namespace           = "AWS/SageMaker"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 1
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  period              = 60
  statistic           = "Average"
  alarm_actions       = [aws_sns_topic.alarmstate.arn]
  ok_actions          = [aws_sns_topic.okstate.arn]
  dimensions = { EndpointName = aws_sagemaker_endpoint.main.name,
  VariantName = aws_sagemaker_endpoint_configuration.main.production_variants[0].variant_name }

  depends_on = [aws_sagemaker_endpoint.main, aws_sns_topic.alarmstate, aws_sns_topic.okstate]
}
