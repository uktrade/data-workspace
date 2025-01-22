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


resource "aws_cloudwatch_metric_alarm" "cloudwatch_alarm" {
  count = length(var.alarms)

  alarm_name          = "${var.alarms[count.index].alarm_name_prefix}-${aws_sagemaker_endpoint.sagemaker_endpoint.name}"
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
  dimensions          = count.index == 0 ? {  # TODO: this logic is brittle as it assumes "backlog" has index 0; it would be better to have a logic that rests on the specific name of that metric
                                              EndpointName = aws_sagemaker_endpoint.sagemaker_endpoint.name  # Only EndpointName is used in this case
                                              } : {
                                              EndpointName = aws_sagemaker_endpoint.sagemaker_endpoint.name,  # Both EndpointName and VariantName are used in all other cases
                                              VariantName  = aws_sagemaker_endpoint_configuration.endpoint_config.production_variants[0].variant_name  # Note this logic would not work if there were ever more than one production variant deployed for an LLM
                                            }


  depends_on = [aws_sagemaker_endpoint.sagemaker_endpoint, aws_sns_topic.sns_topic_alarmstate, aws_sns_topic.sns_topic_okstate]
}

resource "aws_sns_topic" "sns_topic_alarmstate" {
  count = length(var.alarms)

  name       = "alarm-alarmstate-${var.alarms[count.index].alarm_name_prefix}-${aws_sagemaker_endpoint.sagemaker_endpoint.name}"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Principal = {
        Resource = "*"
      }
    ]
  })
}

resource "aws_lambda_permission" "allow_sns_alarmstate" {
  count = length(var.alarms)

  statement_id  = "AllowSNS-alarm-${count.index}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.slack_alert_function.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.sns_topic_alarmstate[count.index].arn
}

resource "aws_sns_topic_subscription" "sns_lambda_subscription_alarmstate" {
  count = length(var.alarms)

  topic_arn = aws_sns_topic.sns_topic_alarmstate[count.index].arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.slack_alert_function.arn
}

resource "aws_sns_topic" "sns_topic_okstate" {
  count = length(var.alarms)

  name       = "alarm-okstate-${var.alarms[count.index].alarm_name_prefix}-${aws_sagemaker_endpoint.sagemaker_endpoint.name}"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        },
        Action   = "sns:Publish",
        Resource = "*"
      }
    ]
  })
}

resource "aws_lambda_permission" "allow_sns_okstate" {
  count = length(var.alarms)

  statement_id  = "AllowSNS-ok-${count.index}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.slack_alert_function.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.sns_topic_okstate[count.index].arn
}

resource "aws_sns_topic_subscription" "sns_lambda_subscription_okstate" {
  count = length(var.alarms)

  topic_arn = aws_sns_topic.sns_topic_okstate[count.index].arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.slack_alert_function.arn
}

# Mpping SNS topic ARNs to Slack webhook URLs
locals {
  sns_to_webhook_mapping = merge({
    for idx, alarm in var.alarms :
    aws_sns_topic.sns_topic_alarmstate[idx].arn => alarm.slack_webhook_url
    }, {
    for idx, alarm in var.alarms :
    aws_sns_topic.sns_topic_okstate[idx].arn => alarm.slack_webhook_url
  })
}

data "archive_file" "lambda_payload" {
  type        = "zip"
  source_file = "${path.module}/lambda_function.py"
  output_path = "${path.module}/payload.zip"
}


resource "aws_lambda_function" "slack_alert_function" {
  filename         = data.archive_file.lambda_payload.output_path
  source_code_hash = data.archive_file.lambda_payload.output_base64sha256
  function_name    = "${var.model_name}-slack-alert-lambda"
  role             = aws_iam_role.slack_lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  timeout          = 30

  environment {
    variables = {
      SNS_TO_WEBHOOK_JSON = jsonencode(local.sns_to_webhook_mapping)
    }
  }
}

resource "aws_iam_role" "slack_lambda_role" {
  name = "${var.model_name}-slack-alert-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "slack_lambda_policy" {
  name = "${var.model_name}-slack-alert-lambda-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect   = "Allow",
        Action   = "sns:Publish",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "slack_lambda_policy_attachment" {
  role       = aws_iam_role.slack_lambda_role.name
  policy_arn = aws_iam_policy.slack_lambda_policy.arn
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
