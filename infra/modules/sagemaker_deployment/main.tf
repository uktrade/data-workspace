resource "aws_sagemaker_model" "sagemaker_model" {
  name               = var.model_name
  execution_role_arn = var.execution_role_arn

  primary_container {
    image       = var.container_image
    environment = var.environment_variables

    model_data_source {
      s3_data_source {
        s3_uri           = var.uncompressed_model_uri
        s3_data_type     = "S3Prefix"
        compression_type = "None"
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
  name = var.endpoint_config_name

  production_variants {
    variant_name           = var.variant_name
    model_name             = aws_sagemaker_model.sagemaker_model.name
    instance_type          = var.instance_type
    initial_instance_count = var.initial_instance_count
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
  name                 = var.endpoint_name
  endpoint_config_name = aws_sagemaker_endpoint_configuration.endpoint_config.name
  depends_on           = [aws_sagemaker_endpoint_configuration.endpoint_config, var.sns_success_topic_arn]
}

resource "aws_appautoscaling_target" "autoscaling_target" {
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "endpoint/${aws_sagemaker_endpoint.sagemaker_endpoint.name}/variant/${var.variant_name}"
  scalable_dimension = "sagemaker:variant:DesiredInstanceCount"
  service_namespace  = "sagemaker"
  depends_on         = [aws_sagemaker_endpoint.sagemaker_endpoint, aws_sagemaker_endpoint_configuration.endpoint_config]
}

resource "aws_appautoscaling_policy" "scale_up_policy" {
  name               = "scale-up-policy-${var.model_name}"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.autoscaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.autoscaling_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.autoscaling_target.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    metric_aggregation_type = "Average"
    cooldown                = var.scale_up_cooldown

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = var.scale_up_adjustment
    }
  }
}

resource "aws_appautoscaling_policy" "scale_in_to_zero_policy" {
  name               = "scale-in-to-zero-policy-${var.model_name}"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.autoscaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.autoscaling_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.autoscaling_target.service_namespace

  step_scaling_policy_configuration {
    adjustment_type = "ExactCapacity"


    step_adjustment {
      metric_interval_lower_bound = null # No lower bound to cover everything
      metric_interval_upper_bound = 5    # Upper bound is 5%
      scaling_adjustment          = 0
    }

    step_adjustment {
      metric_interval_lower_bound = 5    # Lower bound starts at 5%
      metric_interval_upper_bound = null # No upper bound
      scaling_adjustment          = 1    # Maintains min capacity of one instance
    }

    cooldown = var.scale_in_to_zero_cooldown
  }
  depends_on = [aws_appautoscaling_target.autoscaling_target]
}

resource "aws_appautoscaling_policy" "scale_in_to_zero_based_on_backlog" {
  name               = "scale-in-to-zero-backlog-policy-${var.model_name}"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.autoscaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.autoscaling_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.autoscaling_target.service_namespace


  step_scaling_policy_configuration {
    adjustment_type = "ExactCapacity" # Set the capacity exactly to zero

    # Step adjustment for when there are zero queries in the backlog
    step_adjustment {
      metric_interval_lower_bound = null # No lower bound (cover everything below 0)
      metric_interval_upper_bound = 0    # Exact match for zero backlog size
      scaling_adjustment          = 0    # Set capacity to zero instances
    }

    # Falllback for any value above 0 to prevent overlap
    step_adjustment {
      metric_interval_lower_bound = 0    # No lower bound (cover everything below 0)
      metric_interval_upper_bound = null # Exact match for zero backlog size
      scaling_adjustment          = 1    # Set capacity to zero instances
    }

    cooldown = var.scale_in_to_zero_cooldown
  }


  depends_on = [aws_appautoscaling_target.autoscaling_target]
}

resource "aws_cloudwatch_log_metric_filter" "unauthorized_operations" {
  name           = "unauthorized-operations-filter"
  log_group_name = var.log_group_name
  pattern        = "{ $.errorCode = \"UnauthorizedOperation\" || $.errorCode = \"AccessDenied\" }"

  metric_transformation {
    name      = "UnauthorizedOperationsCount"
    namespace = "CloudTrailMetrics"
    value     = "1"
  }
}

# Local for alarms with SNS topics
locals {
  alarms_with_sns = [
    for alarm in var.alarms : alarm
    if alarm.sns_topic_name != null
  ]
}


# Local for mapping SNS topic ARNs to Slack webhook URLs
locals {
  sns_to_webhook_mapping = {
    for idx, alarm in local.alarms_with_sns :
    aws_sns_topic.sns_topic[idx].arn => alarm.slack_webhook_url
  }
}

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

  # Conditionally add SNS topics as alarm actions & lazy eval
  alarm_actions = concat(
    var.alarms[count.index].alarm_actions != null ? var.alarms[count.index].alarm_actions : [],
    var.alarms[count.index].sns_topic_name != null ? [
      lookup(
        { for idx, alarm in local.alarms_with_sns :
          alarm.sns_topic_name => aws_sns_topic.sns_topic[idx].arn
        },
        var.alarms[count.index].sns_topic_name,
        null
      )
    ] : []
  )

}

resource "aws_sns_topic" "sns_topic" {
  count = length(local.alarms_with_sns)

  name = local.alarms_with_sns[count.index].sns_topic_name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        },
        Action   = "sns:Publish",
        Resource = "arn:aws:sns:eu-west-2:${var.aws_account_id}:${local.alarms_with_sns[count.index].sns_topic_name}"
      }
    ]
  })

  lifecycle {
    prevent_destroy = false
  }
}


resource "aws_sns_topic_subscription" "sns_lambda_subscription" {
  count = length(local.alarms_with_sns)

  topic_arn = aws_sns_topic.sns_topic[count.index].arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.slack_alert_function.arn
}


data "archive_file" "lambda_payload" {
  type        = "zip"
  source_file = "${path.module}/lambda_function.py"
  output_path = "${path.module}/payload.zip"
}


# Lambda Function for Slack Alerts
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

resource "aws_lambda_permission" "allow_sns" {
  count = length(local.alarms_with_sns)

  statement_id  = "AllowSNS-${count.index}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.slack_alert_function.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.sns_topic[count.index].arn
}
