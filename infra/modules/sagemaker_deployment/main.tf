# SageMaker Model Resource
resource "aws_sagemaker_model" "sagemaker_model" {
  name               = var.model_name
  execution_role_arn = var.execution_role_arn

  primary_container {
    image           = var.container_image
    model_data_url  = var.model_data_url
    environment     = var.environment
  }

  vpc_config {
    security_group_ids = var.security_group_ids
    subnets            = var.subnets
  }
}

# Endpoint Configuration
resource "aws_sagemaker_endpoint_configuration" "endpoint_config" {
  name = var.endpoint_config_name

  production_variants {
    variant_name           = var.variant_name
    model_name             = aws_sagemaker_model.sagemaker_model.name
    instance_type          = var.instance_type
    initial_instance_count = var.initial_instance_count
  }

  async_inference_config {
    client_config {
      max_concurrent_invocations_per_instance = var.max_concurrent_invocations_per_instance
    }
    output_config {
      s3_output_path = var.s3_output_path
    }
  }
}

# Endpoint Resource
resource "aws_sagemaker_endpoint" "sagemaker_endpoint" {
  name                 = var.endpoint_name
  endpoint_config_name = aws_sagemaker_endpoint_configuration.endpoint_config.name
}

# Autoscaling Target Resource
resource "aws_appautoscaling_target" "autoscaling_target" {
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "endpoint/${aws_sagemaker_endpoint.sagemaker_endpoint.name}/variant/${var.variant_name}"
  scalable_dimension = "sagemaker:variant:DesiredInstanceCount"
  service_namespace  = "sagemaker"
}

# Autoscaling Policy for Scaling Up
resource "aws_appautoscaling_policy" "scale_up_policy" {
  name               = "scale-up-policy-${var.model_name}"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.autoscaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.autoscaling_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.autoscaling_target.service_namespace

  step_scaling_policy_configuration {
    adjustment_type          = "ChangeInCapacity"
    metric_aggregation_type  = "Average"
    cooldown                 = var.scale_up_cooldown

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = var.scale_up_adjustment
    }
  }
}

# Autoscaling Policy for Scaling In to Zero
resource "aws_appautoscaling_policy" "scale_in_to_zero_policy" {
  name               = "scale-in-to-zero-policy-${var.model_name}"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.autoscaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.autoscaling_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.autoscaling_target.service_namespace

  step_scaling_policy_configuration {
    adjustment_type = "ExactCapacity"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 0
    }

    cooldown = var.scale_in_to_zero_cooldown
  }
}

# Loop through the alarm definitions to create multiple CloudWatch alarms
resource "aws_cloudwatch_metric_alarm" "cloudwatch_alarm" {
  count = length(var.alarms)

  alarm_name          = var.alarms[count.index].alarm_name
  alarm_description   = var.alarms[count.index].alarm_description
  metric_name         = var.alarms[count.index].metric_name
  namespace           = var.alarms[count.index].namespace
  comparison_operator = var.alarms[count.index].comparison_operator
  threshold           = var.alarms[count.index].threshold
  evaluation_periods  = var.alarms[count.index].evaluation_periods
  datapoints_to_alarm = var.alarms[count.index].datapoints_to_alarm
  period              = var.alarms[count.index].period
  statistic           = var.alarms[count.index].statistic

  # Define dimensions based on the count index - 
  # first alarm will not have a null variantName
  dimensions = count.index == 0 ? {
    EndpointName = aws_sagemaker_endpoint.sagemaker_endpoint.name
  } : {
    EndpointName = aws_sagemaker_endpoint.sagemaker_endpoint.name,
    VariantName  = var.variant_name
  }

  alarm_actions = var.alarms[count.index].alarm_actions
}
