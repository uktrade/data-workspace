
resource "aws_cloudwatch_metric_alarm" "scale_up_from_0_to_1" {

  alarm_name          = "${aws_sagemaker_endpoint.main.name}-scale-up-from-0-to-1"
  alarm_description   = "Where there exists a high backlog and there exists a state of insufficient data for any of CPU, GPU, RAM (i.e. there are tasks to do but no instance is live to perform it)"
  evaluation_periods  = var.evaluation_periods_high
  datapoints_to_alarm = var.datapoints_to_alarm_high
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 0.5  # boolean comparison operator does not exist so this uses TRUE=1 and FALSE=0 instead
  alarm_actions       = [aws_appautoscaling_policy.scale_up_from_0_to_1.arn, aws_sns_topic.scale_up_from_0_to_1_alarmstate.arn]
  ok_actions          = [aws_sns_topic.scale_up_from_0_to_1_okstate.arn]

  metric_query {
    id          = "result"
    expression  = "ABS(backlog>=${var.backlog_threshold_high}) AND (FILL(cpu, 0)==0 OR FILL(gpu,0)==0 OR FILL(ram,0)==0)"
    return_data = "true"
    period      = 60

  }

  metric_query {
    id = "backlog"

    metric {
      metric_name = "ApproximateBacklogSize"
      namespace   = "AWS/SageMaker"
      period      = 60
      stat        = "Maximum"
      unit        = "Count"

      dimensions = {
        EndpointName = aws_sagemaker_endpoint.main.name
        }
    }
  }

  metric_query {
    id = "cpu"

    metric {
      metric_name = "CPUUtilization"
      namespace   = "/aws/sagemaker/Endpoints"
      period      = 60
      stat        = "Average"
      unit        = "Percent"  # NOTE: 100% for each vCPU available

      dimensions = {
        EndpointName = aws_sagemaker_endpoint.main.name,
        VariantName = aws_sagemaker_endpoint_configuration.main.production_variants[0].variant_name
        }
    }
  }
  metric_query {
    id = "gpu"

    metric {
      metric_name = "GPUUtilization"
      namespace   = "/aws/sagemaker/Endpoints"
      period      = 60
      stat        = "Average"
      unit        = "Percent"  # NOTE: 100% for each GPU available

      dimensions = {
        EndpointName = aws_sagemaker_endpoint.main.name,
        VariantName = aws_sagemaker_endpoint_configuration.main.production_variants[0].variant_name
        }
    }
  }
  metric_query {
    id = "ram"

    metric {
      metric_name = "MemoryUtilization"
      namespace   = "/aws/sagemaker/Endpoints"
      period      = 60
      stat        = "Average"
      unit        = "Percent"  # NOTE: 100% is total in this case

      dimensions = {
        EndpointName = aws_sagemaker_endpoint.main.name,
        VariantName = aws_sagemaker_endpoint_configuration.main.production_variants[0].variant_name
        }
    }
  }

  depends_on = [aws_sagemaker_endpoint.main, aws_sns_topic.scale_up_from_0_to_1_alarmstate, aws_sns_topic.scale_up_from_0_to_1_okstate]
}


resource "aws_cloudwatch_metric_alarm" "scale_down_from_n_to_nm1" {

  alarm_name          = "${aws_sagemaker_endpoint.main.name}-scale-down-from-n-to-nm1"
  alarm_description   = "Where there exists a high backlog and a low state of any of CPU, GPU, RAM (i.e. live instances are excessive for the current tasks)"
  evaluation_periods  = var.evaluation_periods_low
  datapoints_to_alarm = var.datapoints_to_alarm_low
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 0.5  # boolean comparison operator does not exist so this uses TRUE=1 and FALSE=0 instead
  alarm_actions       = [aws_appautoscaling_policy.scale_down_from_n_to_nm1.arn]
  ok_actions          = []

  metric_query {
    id          = "result"
    expression  = "ABS(backlog>=${var.backlog_threshold_high} AND (cpu<=${var.cpu_threshold_low} OR gpu<=${var.gpu_threshold_low} OR ram<=${var.ram_threshold_low}))"
    return_data = "true"
    period      = 60

  }

  metric_query {
    id = "backlog"

    metric {
      metric_name = "ApproximateBacklogSize"
      namespace   = "AWS/SageMaker"
      period      = 60
      stat        = "Maximum"
      unit        = "Count"

      dimensions = {
        EndpointName = aws_sagemaker_endpoint.main.name
        }
    }
  }

  metric_query {
    id = "cpu"

    metric {
      metric_name = "CPUUtilization"
      namespace   = "/aws/sagemaker/Endpoints"
      period      = 60
      stat        = "Average"
      unit        = "Percent"  # NOTE: 100% for each vCPU available

      dimensions = {
        EndpointName = aws_sagemaker_endpoint.main.name,
        VariantName = aws_sagemaker_endpoint_configuration.main.production_variants[0].variant_name
        }
    }
  }
  metric_query {
    id = "gpu"

    metric {
      metric_name = "GPUUtilization"
      namespace   = "/aws/sagemaker/Endpoints"
      period      = 60
      stat        = "Average"
      unit        = "Percent"  # NOTE: 100% for each GPU available

      dimensions = {
        EndpointName = aws_sagemaker_endpoint.main.name,
        VariantName = aws_sagemaker_endpoint_configuration.main.production_variants[0].variant_name
        }
    }
  }
  metric_query {
    id = "ram"

    metric {
      metric_name = "MemoryUtilization"
      namespace   = "/aws/sagemaker/Endpoints"
      period      = 60
      stat        = "Average"
      unit        = "Percent"  # NOTE: 100% is total in this case

      dimensions = {
        EndpointName = aws_sagemaker_endpoint.main.name,
        VariantName = aws_sagemaker_endpoint_configuration.main.production_variants[0].variant_name
        }
    }
  }

  depends_on = [aws_sagemaker_endpoint.main]
}



resource "aws_cloudwatch_metric_alarm" "scale_down_from_n_to_0" {

  alarm_name          = "${aws_sagemaker_endpoint.main.name}-scale-down-from-n-to-0"
  alarm_description   = "Where there exists a low backlog and a low state of any of CPU, GPU, RAM (i.e. there is no task to come and live instances are excessive for any tasks currently in process)"
  evaluation_periods  = var.evaluation_periods_low
  datapoints_to_alarm = var.datapoints_to_alarm_low
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 0.5  # boolean comparison operator does not exist so this uses TRUE=1 and FALSE=0 instead
  alarm_actions       = [aws_appautoscaling_policy.scale_down_from_n_to_0.arn, aws_sns_topic.scale_down_from_n_to_0_alarmstate.arn]
  ok_actions          = [aws_sns_topic.scale_down_from_n_to_0_okstate.arn]

  metric_query {
    id          = "result"
    expression  = "ABS(backlog<${var.backlog_threshold_low} AND (cpu<=${var.cpu_threshold_low} OR gpu<=${var.gpu_threshold_low} OR ram<=${var.ram_threshold_low}))"
    return_data = "true"
    period      = 60

  }

  metric_query {
    id = "backlog"

    metric {
      metric_name = "ApproximateBacklogSize"
      namespace   = "AWS/SageMaker"
      period      = 60
      stat        = "Maximum"
      unit        = "Count"

      dimensions = {
        EndpointName = aws_sagemaker_endpoint.main.name
        }
    }
  }

  metric_query {
    id = "cpu"

    metric {
      metric_name = "CPUUtilization"
      namespace   = "/aws/sagemaker/Endpoints"
      period      = 60
      stat        = "Average"
      unit        = "Percent"  # NOTE: 100% for each vCPU available

      dimensions = {
        EndpointName = aws_sagemaker_endpoint.main.name,
        VariantName = aws_sagemaker_endpoint_configuration.main.production_variants[0].variant_name
        }
    }
  }
  metric_query {
    id = "gpu"

    metric {
      metric_name = "GPUUtilization"
      namespace   = "/aws/sagemaker/Endpoints"
      period      = 60
      stat        = "Average"
      unit        = "Percent"  # NOTE: 100% for each GPU available

      dimensions = {
        EndpointName = aws_sagemaker_endpoint.main.name,
        VariantName = aws_sagemaker_endpoint_configuration.main.production_variants[0].variant_name
        }
    }
  }
  metric_query {
    id = "ram"

    metric {
      metric_name = "MemoryUtilization"
      namespace   = "/aws/sagemaker/Endpoints"
      period      = 60
      stat        = "Average"
      unit        = "Percent"  # NOTE: 100% is total in this case

      dimensions = {
        EndpointName = aws_sagemaker_endpoint.main.name,
        VariantName = aws_sagemaker_endpoint_configuration.main.production_variants[0].variant_name
        }
    }
  }
  depends_on = [aws_sagemaker_endpoint.main, aws_sns_topic.scale_down_from_n_to_0_alarmstate, aws_sns_topic.scale_down_from_n_to_0_okstate]
}



resource "aws_cloudwatch_metric_alarm" "scale_up_from_n_to_np1" {

  alarm_name          = "${aws_sagemaker_endpoint.main.name}-scale-up-from-n-to-np1"
  alarm_description   = "Where there exists a high backlog and a high state of any of CPU, GPU, RAM (i.e. live instances are insufficient for the tasks being performed)"
  evaluation_periods  = var.evaluation_periods_high
  datapoints_to_alarm = var.datapoints_to_alarm_high
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 0.5  # boolean comparison operator does not exist so this uses TRUE=1 and FALSE=0 instead
  alarm_actions       = [aws_appautoscaling_policy.scale_up_from_n_to_np1.arn]
  ok_actions          = []

  metric_query {
    id          = "result"
    expression  = "ABS(backlog>=${var.backlog_threshold_high} AND (cpu>=${var.cpu_threshold_high} OR gpu>=${var.gpu_threshold_high} OR ram>=${var.ram_threshold_high}))"
    return_data = "true"
    period      = 60

  }

  metric_query {
    id = "backlog"

    metric {
      metric_name = "ApproximateBacklogSize"
      namespace   = "AWS/SageMaker"
      period      = 60
      stat        = "Maximum"
      unit        = "Count"

      dimensions = {
        EndpointName = aws_sagemaker_endpoint.main.name
        }
    }
  }

  metric_query {
    id = "cpu"

    metric {
      metric_name = "CPUUtilization"
      namespace   = "/aws/sagemaker/Endpoints"
      period      = 60
      stat        = "Average"
      unit        = "Percent"  # NOTE: 100% for each vCPU available

      dimensions = {
        EndpointName = aws_sagemaker_endpoint.main.name,
        VariantName = aws_sagemaker_endpoint_configuration.main.production_variants[0].variant_name
        }
    }
  }
  metric_query {
    id = "gpu"

    metric {
      metric_name = "GPUUtilization"
      namespace   = "/aws/sagemaker/Endpoints"
      period      = 60
      stat        = "Average"
      unit        = "Percent"  # NOTE: 100% for each GPU available

      dimensions = {
        EndpointName = aws_sagemaker_endpoint.main.name,
        VariantName = aws_sagemaker_endpoint_configuration.main.production_variants[0].variant_name
        }
    }
  }
  metric_query {
    id = "ram"

    metric {
      metric_name = "MemoryUtilization"
      namespace   = "/aws/sagemaker/Endpoints"
      period      = 60
      stat        = "Average"
      unit        = "Percent"  # NOTE: 100% is total in this case

      dimensions = {
        EndpointName = aws_sagemaker_endpoint.main.name,
        VariantName = aws_sagemaker_endpoint_configuration.main.production_variants[0].variant_name
        }
    }
  }

  depends_on = [aws_sagemaker_endpoint.main]
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
  dimensions = {
      EndpointName = aws_sagemaker_endpoint.main.name,
      VariantName = aws_sagemaker_endpoint_configuration.main.production_variants[0].variant_name
      }

  depends_on = [aws_sagemaker_endpoint.main]
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
  dimensions = {
      EndpointName = aws_sagemaker_endpoint.main.name,
      VariantName = aws_sagemaker_endpoint_configuration.main.production_variants[0].variant_name
      }

  depends_on = [aws_sagemaker_endpoint.main]
}
