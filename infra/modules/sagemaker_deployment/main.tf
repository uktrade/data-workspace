resource "aws_sagemaker_model" "sagemaker_model" {
  name               = var.model_name
  execution_role_arn = var.execution_role_arn

  primary_container {
    image       = var.container_image
    environment = var.environment_variables

    model_data_source {
      s3_data_source {
        s3_uri           = var.model_uri
        s3_data_type     = "S3Prefix"
        compression_type = var.model_uri_compression
        model_access_config {
          accept_eula = true
        }
      }
    }
  }

  vpc_config {
    security_group_ids = var.security_group_ids
    subnets            = var.subnets
  }
}


resource "aws_sagemaker_endpoint_configuration" "endpoint_config" {
  name = "${aws_sagemaker_model.sagemaker_model.name}-endpoint-config"

  production_variants {
    variant_name           = "AllTraffic"
    model_name             = aws_sagemaker_model.sagemaker_model.name
    instance_type          = var.instance_type
    initial_instance_count = 1
  }

  async_inference_config {
    output_config {
      s3_output_path = var.s3_output_path
      notification_config {
        include_inference_response_in = ["SUCCESS_NOTIFICATION_TOPIC"]
        success_topic                 = var.sns_success_topic_arn
      }
    }
  }
}


resource "aws_sagemaker_endpoint" "sagemaker_endpoint" {
  name = "${aws_sagemaker_model.sagemaker_model.name}-endpoint"

  endpoint_config_name = aws_sagemaker_endpoint_configuration.endpoint_config.name
  depends_on           = [aws_sagemaker_endpoint_configuration.endpoint_config, var.sns_success_topic_arn]
}


resource "aws_appautoscaling_target" "autoscaling_target" {
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "endpoint/${aws_sagemaker_endpoint.sagemaker_endpoint.name}/variant/${aws_sagemaker_endpoint_configuration.endpoint_config.production_variants[0].variant_name}" # Note this logic would not work if there were ever more than one production variant deployed for an LLM
  scalable_dimension = "sagemaker:variant:DesiredInstanceCount"
  service_namespace  = "sagemaker"
  depends_on         = [aws_sagemaker_endpoint.sagemaker_endpoint, aws_sagemaker_endpoint_configuration.endpoint_config]
}


resource "aws_appautoscaling_policy" "scale_up_to_n_policy" {
  name = "scale-up-to-n-policy-${var.model_name}"

  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.autoscaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.autoscaling_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.autoscaling_target.service_namespace
  depends_on         = [aws_appautoscaling_target.autoscaling_target]

  step_scaling_policy_configuration {
    adjustment_type = "ChangeInCapacity"
    cooldown        = var.scale_up_cooldown

    step_adjustment {
      scaling_adjustment          = 1
      metric_interval_lower_bound = 0
      metric_interval_upper_bound = null
    }
  }
}


resource "aws_appautoscaling_policy" "scale_down_to_n_policy" {
  name = "scale-down-to-n-policy-${var.model_name}"

  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.autoscaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.autoscaling_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.autoscaling_target.service_namespace
  depends_on         = [aws_appautoscaling_target.autoscaling_target]

  step_scaling_policy_configuration {
    adjustment_type = "ChangeInCapacity"
    cooldown        = var.scale_down_cooldown

    step_adjustment {
      scaling_adjustment          = -1
      metric_interval_lower_bound = null
      metric_interval_upper_bound = 0
    }
  }
}


resource "aws_appautoscaling_policy" "scale_up_to_one_policy" {
  name = "scale-up-to-one-policy-${var.model_name}"

  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.autoscaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.autoscaling_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.autoscaling_target.service_namespace
  depends_on         = [aws_appautoscaling_target.autoscaling_target]

  step_scaling_policy_configuration {
    adjustment_type = "ExactCapacity"
    cooldown        = var.scale_up_cooldown

    step_adjustment {
      scaling_adjustment          = 1 # means set =1 (NOT add or subtract)
      metric_interval_lower_bound = 0
      metric_interval_upper_bound = null
    }
  }
}


resource "aws_appautoscaling_policy" "scale_down_to_zero_policy" {
  name = "scale-down-to-zero-policy-${var.model_name}"

  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.autoscaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.autoscaling_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.autoscaling_target.service_namespace
  depends_on         = [aws_appautoscaling_target.autoscaling_target]

  step_scaling_policy_configuration {
    adjustment_type = "ExactCapacity"
    cooldown        = var.scale_down_cooldown

    step_adjustment {
      scaling_adjustment          = 0 # means set =0 (NOT add or subtract)
      metric_interval_lower_bound = null
      metric_interval_upper_bound = 0
    }
  }
}


# Mapping SNS topic ARNs to Slack webhook URLs
locals {
  sns_to_webhook_mapping = merge({
    for idx, alarm in var.alarms :
    replace(aws_sns_topic.sns_topic_alarmstate[idx].arn, "arn:aws:sns:eu-west-2:${var.aws_account_id}:", "") => alarm.slack_webhook_url
    }, {
    for idx, alarm in var.alarms :
    replace(aws_sns_topic.sns_topic_okstate[idx].arn, "arn:aws:sns:eu-west-2:${var.aws_account_id}:", "") => alarm.slack_webhook_url
    }, {
    for idx, alarm_composite in var.alarm_composites :
    replace(aws_sns_topic.sns_topic_composite[idx].arn, "arn:aws:sns:eu-west-2:${var.aws_account_id}:", "") => alarm_composite.slack_webhook_url
    }
  )
}


resource "aws_cloudwatch_log_metric_filter" "unauthorized_operations" {
  name           = "unauthorized-operations-filter"
  log_group_name = "/aws/sagemaker/Endpoints/${aws_sagemaker_endpoint.sagemaker_endpoint.name}"
  pattern        = "{ $.errorCode = \"UnauthorizedOperation\" || $.errorCode = \"AccessDenied\" }"

  metric_transformation {
    name      = "UnauthorizedOperationsCount"
    namespace = "CloudTrailMetrics"
    value     = "1"
  }
}
