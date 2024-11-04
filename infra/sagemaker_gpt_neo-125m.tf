
resource "aws_sagemaker_model" "gpt_neo_125m" {
  name               = "gpt-neo-125m"
  execution_role_arn = aws_iam_role.inference_role.arn

  primary_container {
    image = "${var.hugging_face_model_image}"
    model_data_url = "${var.sagemaker_models_folder}/gpt-neo-125m.tar.gz"
    environment = {
      "HF_MODEL_ID": "/opt/ml/model/", # model_id from hf.co/models
      "SM_NUM_GPUS": 1, # Number of GPU used per replica
      "MAX_INPUT_LENGTH": 1024,  # Max length of input text
      "MAX_TOTAL_TOKENS": 2048,  # Max length of the generation (including input text)
    }
  }

  vpc_config {
    security_group_ids = ["${aws_security_group.notebooks.id}"]
    subnets = aws_subnet.private_without_egress.*.id
  }
}

resource "aws_sagemaker_endpoint" "gpt_neo_125m_endpoint" {
  name = "gpt-neo-125m-endpoint"
  endpoint_config_name = aws_sagemaker_endpoint_configuration.sagemaker_endpoint_configuration_gpt_neo_125m_endpoint.name
}

resource "aws_sagemaker_endpoint_configuration" "sagemaker_endpoint_configuration_gpt_neo_125m_endpoint" {
  name = "sagemaker-endpoint-config-gpt-neo-125m"

  production_variants {
    variant_name           = "gpt-neo-125m-endpoint-example-1"
    model_name             = aws_sagemaker_model.gpt_neo_125m.name
    instance_type          = "ml.g5.2xlarge"
    initial_instance_count = 1
    container_startup_health_check_timeout_in_seconds = 90
  }

  # Async config
  async_inference_config {
    client_config {
        max_concurrent_invocations_per_instance = 1
    }
    output_config {
        s3_output_path = "https://${data.aws_s3_bucket.sagemaker_default_bucket.bucket_regional_domain_name}"
    }
 }
}

# Auto scaling Target for the endpoint of this model
resource "aws_appautoscaling_target" "sagemaker_target_gpt_neo_125m_endpoint" {
  # Max 2 instances at any given time
  max_capacity = 2 
  # Min capacity = 1 ensures our endpoint is at a minimum when not needed but ready to go
  min_capacity = 1
  resource_id = "endpoint/${aws_sagemaker_endpoint.gpt_neo_125m_endpoint.name}/variant/gpt-neo-125m-endpoint-example-1"
  # Number of desired instance count for the endpoint which can be modified by auto-scaling
  scalable_dimension = "sagemaker:variant:DesiredInstanceCount"
  service_namespace = "sagemaker"
}

# Scale up from 0 
resource "aws_appautoscaling_policy" "has_backlog_without_capacity_gpt_neo_125m_endpoint" {
  name                  = "HasBacklogWithoutCapacity-ScalingPolicy"
  service_namespace     = "sagemaker"
  resource_id           = aws_appautoscaling_target.sagemaker_target_gpt_neo_125m_endpoint.resource_id
  scalable_dimension    = aws_appautoscaling_target.sagemaker_target_gpt_neo_125m_endpoint.scalable_dimension
  policy_type           = "StepScaling"

  step_scaling_policy_configuration {
    adjustment_type          = "ChangeInCapacity"  # Changes instance count by the specified value
    metric_aggregation_type  = "Average"
    cooldown                 = 300  # Wait time for previous scaling activity before starting a new one

    # Increase the instance count by 1 if there are requests in the queue
    step_adjustment {
      metric_interval_lower_bound = 0  # The lower bound for metric interval
      scaling_adjustment          = 1  # Increase instance count by 1
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "has_backlog_without_capacity_alarm_gpt_neo_125m_endpoint" {
  alarm_name          = "HasBacklogWithoutCapacity-Alarm-GPT-Neo-125m"
  alarm_description   = "Trigger scaling policy when the SageMaker endpoint has pending requests in the queue."
  metric_name         = "HasBacklogWithoutCapacity"
  namespace           = "AWS/SageMaker"
  statistic           = "Average"
  period              = 60  # Data aggregation period (seconds)
  evaluation_periods  = 2   # Number of periods to evaluate before triggering the alarm
  datapoints_to_alarm = 2   # Data points that must be breaching to trigger alarm
  threshold           = 1   # Trigger alarm if the backlog metric is greater or equal to 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "missing"

  dimensions = {
    EndpointName = aws_sagemaker_endpoint.gpt_neo_125m_endpoint.name
  }

  # When the alarm state is triggered, initiate the scaling policy to scale up the endpoint
  alarm_actions = [aws_appautoscaling_policy.has_backlog_without_capacity_gpt_neo_125m_endpoint.arn]
}

# Autoscaling policy based on usage metrics around CPU % n.b. this may need altering 
#  if using a GPU on the Scale out policy
resource "aws_appautoscaling_policy" "scale_out_cpu_sagemaker_target_gpt_neo_125m_endpoint" {
  name               = "scale-out-policy-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.sagemaker_target_gpt_neo_125m_endpoint.resource_id
  scalable_dimension = aws_appautoscaling_target.sagemaker_target_gpt_neo_125m_endpoint.scalable_dimension
  service_namespace  = aws_appautoscaling_target.sagemaker_target_gpt_neo_125m_endpoint.service_namespace

  # Config for the target tracking scaling policy
  target_tracking_scaling_policy_configuration {
    customized_metric_specification {
      metric_name = "CPUUtilization"
      namespace   = "AWS/SageMaker"  
      statistic   = "Average"
      unit        = "Percent"
    }

    target_value       = 70.0  # Scale out if CPU utilization exceeds 70%
    scale_in_cooldown  = 60    # Cooldown to prevent frequent scaling in
    scale_out_cooldown = 60    # Cooldown to prevent frequent scaling out
  }
}

#  Scale in - using cloudwatch alarm to ensure we have distinct thresholds
#  Alongside a step scaling policy
#  Now altered for low CPU utilisation as metric for inovcations not present 
resource "aws_cloudwatch_metric_alarm" "scale_in_alarm_gpt_neo_125m_endpoint" {
  alarm_name          = "sm-low-cpu-util"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 3 # Increased eval periods to filter short-lived spikes (health check related)
  metric_name         = "CPUUtilization"
  namespace           = "/aws/sagemaker/Endpoints"
  period              = 60
  statistic           = "Average"
  threshold           = 5.0  # Trigger scale-in if utilization drops below 5%
  

  dimensions = {
    EndpointName = aws_sagemaker_endpoint.gpt_neo_125m_endpoint.name
    VariantName = "gpt-neo-125m-endpoint-example-1"
  }

  alarm_description = "Alarm if SageMaker CPU util rate  <5%. Triggers scale in due to being idle."
  alarm_actions     = [aws_appautoscaling_policy.scale_in_to_zero_gpt_neo_125m_endpoint.arn]
  # treat_missing_data = "breaching"  # Treat missing data as breaching to force evaluation
}

# Alternative: Memory Utilization
resource "aws_cloudwatch_metric_alarm" "scale_in_memory_alarm_gpt_neo_125m_endpoint" {
  alarm_name          = "sm-low-memory-util"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 3
  metric_name         = "MemoryUtilization"
  namespace           = "/aws/sagemaker/Endpoints"
  period              = 60
  statistic           = "Average"
  threshold           = 4.0  # Trigger scale-in if memory utilization drops below 4%
  

  dimensions = {
    EndpointName = aws_sagemaker_endpoint.gpt_neo_125m_endpoint.name
    VariantName = "gpt-neo-125m-endpoint-example-1"
  }

  alarm_description = "SageMaker endpoint alarm if memory utilization < 4%"
  alarm_actions     = [aws_appautoscaling_policy.scale_in_to_zero_gpt_neo_125m_endpoint.arn]
  # treat_missing_data = "breaching"  # Treat missing data as breaching to force evaluation
}

# Step Scaling Policy for Scaling In to Zero which the cloudwatch alarms utilise
resource "aws_appautoscaling_policy" "scale_in_to_zero_gpt_neo_125m_endpoint" {
  name               = "scale-in-to-zero-policy"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.sagemaker_target_gpt_neo_125m_endpoint.resource_id
  scalable_dimension = aws_appautoscaling_target.sagemaker_target_gpt_neo_125m_endpoint.scalable_dimension
  service_namespace  = aws_appautoscaling_target.sagemaker_target_gpt_neo_125m_endpoint.service_namespace

  step_scaling_policy_configuration {
    adjustment_type = "ExactCapacity"

    # Adjust capacity to 1 when underutilization is detected
     step_adjustment {
      metric_interval_lower_bound = 0  # Lower bound is set to 0 to cover all possible metric values
      scaling_adjustment          = 1  # Set capacity to 1 instance
    }

    cooldown = 120  # Longer cooldown to prevent frequent scale-in actions
  }
}
