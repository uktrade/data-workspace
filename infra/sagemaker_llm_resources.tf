##################################################################################################################
# GPT Neo 125M parameter endpoint and associated alarms and policies
#################################################################################################################

module "gpt_neo_125_deployment" {
  source             = "./modules/sagemaker_deployment"
  model_name         = "gpt-neo-125m"
  execution_role_arn = module.iam.inference_role
  container_image    = var.hugging_face_model_image
  model_data_url     = "${var.sagemaker_models_folder}/gpt-neo-125m.tar.gz"
  environment = {
    "HF_MODEL_ID"      = "/opt/ml/model/"
    "SM_NUM_GPUS"      = 1
    "MAX_INPUT_LENGTH" = 1024
    "MAX_TOTAL_TOKENS" = 2048
  }
  security_group_ids        = [aws_security_group.notebooks.id]
  subnets                   = aws_subnet.private_without_egress.*.id
  endpoint_config_name      = "sagemaker-endpoint-config-gpt-neo-125m"
  endpoint_name             = "gpt-neo-125-endpoint"
  variant_name              = "gpt-neo-125m-endpoint-example"
  instance_type             = "ml.g5.2xlarge"
  s3_output_path            = "https://${module.iam.default_sagemaker_bucket.bucket_regional_domain_name}"
  initial_instance_count    = 1
  max_capacity              = 2
  min_capacity              = 0
  scale_up_adjustment       = 1
  scale_up_cooldown         = 60
  scale_in_to_zero_cooldown = 120

  alarms = [
    {
      alarm_name          = "backlog-alarm-${module.gpt_neo_125_deployment.endpoint_name}"
      alarm_description   = "Scale up to 1 when queries are in the backlog, if 0 instances"
      metric_name         = "HasBacklogWithoutCapacity"
      namespace           = "AWS/SageMaker"
      comparison_operator = "GreaterThanOrEqualToThreshold"
      threshold           = 1
      evaluation_periods  = 1
      datapoints_to_alarm = 1
      period              = 30
      statistic           = "Average"
      alarm_actions       = [module.gpt_neo_125_deployment.scale_up_policy_arn]
    },
    {
      alarm_name          = "low-cpu-alarm-${module.gpt_neo_125_deployment.endpoint_name}"
      alarm_description   = "Scale in to zero when CPU < 5%"
      metric_name         = "CPUUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "LessThanThreshold"
      threshold           = 5.0
      evaluation_periods  = 3
      datapoints_to_alarm = 2 # 2 out of 5 periods breaching then scale down to ensure 
      period              = 60
      statistic           = "Average"
      alarm_actions       = [module.gpt_neo_125_deployment.scale_in_to_zero_policy_arn]
    },
    {
      alarm_name          = "no-query-in-backlog-alarm-${module.gpt_neo_125_deployment.endpoint_name}"
      alarm_description   = "Scale in to zero when no queries are in the backlog for > 3 minutes"
      metric_name         = "ApproximateBacklogSize"
      namespace           = "AWS/SageMaker"
      comparison_operator = "LessThanThreshold"
      threshold           = 0
      evaluation_periods  = 3
      datapoints_to_alarm = 2 # 2 out of 3 periods breaching then scale down to ensure 
      period              = 60
      statistic           = "Sum"
      alarm_actions       = [module.gpt_neo_125_deployment.scale_in_to_zero_based_on_backlog_arn]
    },
    {
      alarm_name          = "high-cpu-alarm-${module.gpt_neo_125_deployment.endpoint_name}"
      alarm_description   = "Scale out when CPU is at 70% threshold"
      metric_name         = "CPUUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "GreaterThanThreshold"
      threshold           = 70
      evaluation_periods  = 1
      datapoints_to_alarm = 1
      period              = 60
      statistic           = "Average"
      alarm_actions       = [module.gpt_neo_125_deployment.scale_up_policy_arn]
    },
    {
      alarm_name          = "high-memory-alarm-${module.gpt_neo_125_deployment.endpoint_name}"
      alarm_description   = "Scale up memory usage > 80%"
      metric_name         = "MemoryUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "GreaterThanThreshold"
      threshold           = 80
      evaluation_periods  = 2
      datapoints_to_alarm = 1
      period              = 60
      statistic           = "Average"
      alarm_actions       = [module.gpt_neo_125_deployment.scale_up_policy_arn]
    },
    {
      alarm_name          = "high-GPU-alarm-${module.gpt_neo_125_deployment.endpoint_name}"
      alarm_description   = "Scale up GPU usage > 70%"
      metric_name         = "GPUUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "GreaterThanThreshold"
      threshold           = 70
      evaluation_periods  = 2
      datapoints_to_alarm = 1
      period              = 60
      statistic           = "Average"
      alarm_actions       = [module.gpt_neo_125_deployment.scale_up_policy_arn]
    },
    {
      alarm_name          = "network-spike-alarm-${module.gpt_neo_125_deployment.endpoint_name}"
      alarm_description   = "Scale up to 1 (deactivated) when endpoint experiences a backlog of requests beyond threshold"
      metric_name         = "ApproximateBacklogSize"
      namespace           = "AWS/SageMaker"
      comparison_operator = "GreaterThanThreshold"
      threshold           = 10 # More than 10 requests requires scale up
      evaluation_periods  = 2
      datapoints_to_alarm = 2
      period              = 30
      statistic           = "Average"
    },
    {
      alarm_name          = "disk-util-alarm-${module.gpt_neo_125_deployment.endpoint_name}"
      alarm_description   = "Alerts when disk util is high"
      metric_name         = "DiskUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "GreaterThanThreshold"
      threshold           = 80
      evaluation_periods  = 2
      datapoints_to_alarm = 2
      period              = 30
      statistic           = "Average"
    },
    # {
    #   alarm_name          = "latency-p95-${module.gpt_neo_125_deployment.endpoint_name}"
    #   alarm_description   = "Alerts when P95 Model Latency exceeds baseline by 25%"
    #   metric_name         = "ModelLatency"
    #   namespace           = "AWS/SageMaker"
    #   comparison_operator = "GreaterThanThreshold"
    #   threshold           = 900000 * 1.25 # Avg is 9 minutes or so due to cold starts, so omitting for now
    #   evaluation_periods  = 3
    #   datapoints_to_alarm = 2
    #   period              = 60
    #   statistic           = "Average"
    # },
    # {
    #   alarm_name          = "latency-p99-${module.gpt_neo_125_deployment.endpoint_name}"
    #   alarm_description   = "Scales up (deactivated) when P95 Model Latency exceeds baseline by 50%"
    #   metric_name         = "ModelLatency"
    #   namespace           = "AWS/SageMaker"
    #   comparison_operator = "GreaterThanThreshold"
    #   threshold           = 900000 * 1.50 # Avg is 600 or so, post cold start up
    #   evaluation_periods  = 3
    #   datapoints_to_alarm = 2
    #   period              = 60
    #   statistic           = "Average"
    # },
    {
      alarm_name          = "error-rate-high-${module.gpt_neo_125_deployment.endpoint_name}"
      alarm_description   = "Scales up (deactivated) when Inocation Error rate exceeds 1% over 5 minutes"
      metric_name         = "Invocation4XXErrors"
      namespace           = "AWS/SageMaker"
      comparison_operator = "GreaterThanThreshold"
      threshold           = 200 * 0.01 # Assumes 200 queries within 5 minutes, so 1% of that figure
      evaluation_periods  = 1
      datapoints_to_alarm = 1
      period              = 300
      statistic           = "Sum"
    }
  ]

}


##################################################################################################################
# Llama 3.2 1B parameter endpoint and associated alarms and policies
#################################################################################################################

module "llama_3_2_1b_deployment" {
  source             = "./modules/sagemaker_deployment"
  model_name         = "Llama-3-2-1B"
  execution_role_arn = module.iam.inference_role
  container_image    = var.hugging_face_model_image
  model_data_url     = "${var.sagemaker_models_folder}/Llama-3.2-1B.tar.gz"
  environment = {
    "HF_MODEL_ID"      = "/opt/ml/model/"
    "SM_NUM_GPUS"      = 1
    "MAX_INPUT_LENGTH" = 1024
    "MAX_TOTAL_TOKENS" = 2048
  }
  security_group_ids        = [aws_security_group.notebooks.id]
  subnets                   = aws_subnet.private_without_egress.*.id
  endpoint_config_name      = "sagemaker-endpoint-config-llama-3-2-1B"
  endpoint_name             = "llama-3-2-1b-endpoint"
  variant_name              = "llama-3-2-1B-endpoint-example"
  instance_type             = "ml.g5.2xlarge"
  initial_instance_count    = 1
  s3_output_path            = "https://${module.iam.default_sagemaker_bucket.bucket_regional_domain_name}"
  max_capacity              = 2
  min_capacity              = 0
  scale_up_adjustment       = 1
  scale_up_cooldown         = 30
  scale_in_to_zero_cooldown = 120

  alarms = [
    {
      alarm_name          = "backlog-alarm-${module.llama_3_2_1b_deployment.endpoint_name}"
      alarm_description   = "Scale up to 1 when queries are in the backlog, if 0 instances"
      metric_name         = "HasBacklogWithoutCapacity"
      namespace           = "AWS/SageMaker"
      comparison_operator = "GreaterThanOrEqualToThreshold"
      threshold           = 1
      evaluation_periods  = 1
      datapoints_to_alarm = 1
      period              = 30
      statistic           = "Average"
      alarm_actions       = [module.llama_3_2_1b_deployment.scale_up_policy_arn]
    },
    {
      alarm_name          = "low-cpu-alarm-${module.llama_3_2_1b_deployment.endpoint_name}"
      alarm_description   = "Scale in to zero when CPU < 5%"
      metric_name         = "CPUUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "LessThanThreshold"
      threshold           = 5.0
      evaluation_periods  = 3
      datapoints_to_alarm = 2 # 2 out of 3 periods breaching then scale down to ensure 
      period              = 60
      statistic           = "Average"
      alarm_actions       = [module.llama_3_2_1b_deployment.scale_in_to_zero_policy_arn]
    },
    {
      alarm_name          = "no-query-in-backlog-alarm-${module.llama_3_2_1b_deployment.endpoint_name}"
      alarm_description   = "Scale in to zero when no queries are in the backlog for > 3 minutes"
      metric_name         = "ApproximateBacklogSize"
      namespace           = "AWS/SageMaker"
      comparison_operator = "LessThanThreshold"
      threshold           = 0
      evaluation_periods  = 3
      datapoints_to_alarm = 2 # 2 out of 3 periods breaching then scale down to ensure 
      period              = 60
      statistic           = "Sum"
      alarm_actions       = [module.llama_3_2_1b_deployment.scale_in_to_zero_based_on_backlog_arn]
    },
    {
      alarm_name          = "high-cpu-alarm-${module.llama_3_2_1b_deployment.endpoint_name}"
      alarm_description   = "Scale out when CPU is at 70% threshold"
      metric_name         = "CPUUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "GreaterThanThreshold"
      threshold           = 70
      evaluation_periods  = 1
      datapoints_to_alarm = 1
      period              = 60
      statistic           = "Average"
      alarm_actions       = [module.llama_3_2_1b_deployment.scale_up_policy_arn]
    },
    {
      alarm_name          = "high-memory-alarm-${module.llama_3_2_1b_deployment.endpoint_name}"
      alarm_description   = "Scale up memory usage > 80%"
      metric_name         = "MemoryUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "GreaterThanThreshold"
      threshold           = 80
      evaluation_periods  = 2
      datapoints_to_alarm = 1
      period              = 60
      statistic           = "Average"
      alarm_actions       = [module.llama_3_2_1b_deployment.scale_up_policy_arn]
    },
    {
      alarm_name          = "high-GPU-alarm-${module.llama_3_2_1b_deployment.endpoint_name}"
      alarm_description   = "Scale up GPU usage > 70%"
      metric_name         = "GPUUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "GreaterThanThreshold"
      threshold           = 70
      evaluation_periods  = 2
      datapoints_to_alarm = 1
      period              = 60
      statistic           = "Average"
      alarm_actions       = [module.llama_3_2_1b_deployment.scale_up_policy_arn]
    },
    {
      alarm_name          = "network-spike-alarm-${module.llama_3_2_1b_deployment.endpoint_name}"
      alarm_description   = "Scale up to 1 (deactivated) when endpoint experiences a backlog of requests beyond threshold"
      metric_name         = "ApproximateBacklogSize"
      namespace           = "AWS/SageMaker"
      comparison_operator = "GreaterThanThreshold"
      threshold           = 10 # More than 10 requests requires scale up
      evaluation_periods  = 2
      datapoints_to_alarm = 2
      period              = 30
      statistic           = "Average"
    },
    {
      alarm_name          = "disk-util-alarm-${module.llama_3_2_1b_deployment.endpoint_name}"
      alarm_description   = "Alerts when disk util is high"
      metric_name         = "DiskUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "GreaterThanThreshold"
      threshold           = 80
      evaluation_periods  = 2
      datapoints_to_alarm = 2
      period              = 30
      statistic           = "Average"
    },
    # {
    #   alarm_name          = "latency-p95-${module.llama_3_2_1b_deployment.endpoint_name}"
    #   alarm_description   = "Alerts when P95 Model Latency exceeds baseline by 25%"
    #   metric_name         = "ModelLatency"
    #   namespace           = "AWS/SageMaker"
    #   comparison_operator = "GreaterThanThreshold"
    #   threshold           = 900000 * 1.25 # Avg is 9 minutes or so, so omitting
    #   evaluation_periods  = 3
    #   datapoints_to_alarm = 2
    #   period              = 60
    #   statistic           = "Average"
    # },
    # {
    #   alarm_name          = "latency-p99-${module.llama_3_2_1b_deployment.endpoint_name}"
    #   alarm_description   = "Scales up (deactivated) when P95 Model Latency exceeds baseline by 50%"
    #   metric_name         = "ModelLatency"
    #   namespace           = "AWS/SageMaker"
    #   comparison_operator = "GreaterThanThreshold"
    #   threshold           = 900000 * 1.50 # Avg is 9 minutes or so, so omitting
    #   evaluation_periods  = 3
    #   datapoints_to_alarm = 2
    #   period              = 60
    #   statistic           = "Average"
    # },
    {
      alarm_name          = "error-rate-high-${module.llama_3_2_1b_deployment.endpoint_name}"
      alarm_description   = "Scales up (deactivated) when Invocation Error rate exceeds 1% over 5 minutes"
      metric_name         = "Invocation4XXErrors"
      namespace           = "AWS/SageMaker"
      comparison_operator = "GreaterThanThreshold"
      threshold           = 200 * 0.01 # Assumes 200 queries within 5 minutes, so 1% of that figure
      evaluation_periods  = 1
      datapoints_to_alarm = 1
      period              = 300
      statistic           = "Sum"
    }
  ]
}