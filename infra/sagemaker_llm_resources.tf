locals {
  all_endpoint_names = [
    module.gpt_neo_125_deployment.endpoint_name,
    module.llama_3_2_1b_deployment.endpoint_name,
    module.mistral_7b_deployment.endpoint_name,
    module.gemma_2_27b_deployment.endpoint_name,
    module.llama_3_70b_deployment.endpoint_name,
  ]
}

################
# GPT Neo 125m
###############

module "gpt_neo_125_deployment" {
  source                 = "./modules/sagemaker_deployment"
  model_name             = "gpt-neo-125m"
  sns_success_topic_arn  = module.sagemaker_output_mover.sns_success_topic_arn
  execution_role_arn     = module.iam.inference_role
  container_image        = "763104351884.dkr.ecr.eu-west-2.amazonaws.com/huggingface-pytorch-tgi-inference:2.1.1-tgi1.4.0-gpu-py310-cu121-ubuntu20.04"
  uncompressed_model_uri = "s3://jumpstart-cache-prod-eu-west-2/huggingface-textgeneration1/huggingface-textgeneration1-gpt-neo-125m/artifacts/inference-prepack/v2.0.0/"
  environment_variables = {
    "ENDPOINT_SERVER_TIMEOUT" : "3600",
    "HF_MODEL_ID" : "/opt/ml/model",
    "MAX_INPUT_LENGTH" : "1024",
    "MAX_TOTAL_TOKENS" : "2048",
    "MODEL_CACHE_ROOT" : "/opt/ml/model",
    "SAGEMAKER_ENV" : "1",
    "SAGEMAKER_MODEL_SERVER_WORKERS" : "1",
    "SAGEMAKER_PROGRAM" : "inference.py",
    "SM_NUM_GPUS" : "1"
  }
  instance_type             = "ml.g5.2xlarge" # 8 vCPU and 1 GPU and 32 GB-RAM
  security_group_ids        = [aws_security_group.notebooks.id]
  subnets                   = aws_subnet.private_without_egress.*.id
  endpoint_config_name      = "sagemaker-endpoint-config-gpt-neo-125m"
  endpoint_name             = "gpt-neo-125-endpoint"
  variant_name              = "gpt-neo-125m-endpoint-dev"
  s3_output_path            = "https://${module.iam.default_sagemaker_bucket.bucket_regional_domain_name}"
  initial_instance_count    = 1
  max_capacity              = 2
  min_capacity              = 0
  scale_up_adjustment       = 1
  scale_up_cooldown         = 60
  scale_in_to_zero_cooldown = 120
  log_group_name            = "/aws/sagemaker/Endpoints/${module.gpt_neo_125_deployment.endpoint_name}"
  aws_account_id            = data.aws_caller_identity.aws_caller_identity.account_id

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
      sns_topic_name      = "backlog-alarm-${module.gpt_neo_125_deployment.endpoint_name}"
      slack_webhook_url   = var.slack_webhook_backlog_alerts
    },
    {
      alarm_name          = "low-cpu-alarm-${module.gpt_neo_125_deployment.endpoint_name}"
      alarm_description   = "Scale in to zero when CPU < 5%"
      metric_name         = "CPUUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "LessThanThreshold"
      threshold           = 5 * 8 # TODO: Number of vCPUs
      evaluation_periods  = 3
      datapoints_to_alarm = 2
      period              = 60
      statistic           = "Average"
      alarm_actions       = [module.gpt_neo_125_deployment.scale_in_to_zero_policy_arn]
      sns_topic_name      = "low-cpu-alert-${module.gpt_neo_125_deployment.endpoint_name}"
      slack_webhook_url   = var.slack_webhook_cpu_alerts
    },
    {
      alarm_name          = "no-query-in-backlog-alarm-${module.gpt_neo_125_deployment.endpoint_name}"
      alarm_description   = "Scale in to zero when no queries are in the backlog for > 3 minutes"
      metric_name         = "ApproximateBacklogSize"
      namespace           = "AWS/SageMaker"
      comparison_operator = "LessThanThreshold"
      threshold           = 0
      evaluation_periods  = 3
      datapoints_to_alarm = 2
      period              = 60
      statistic           = "Sum"
      alarm_actions       = [module.gpt_neo_125_deployment.scale_in_to_zero_based_on_backlog_arn]
      sns_topic_name      = "no-query-backlog-alarm-${module.gpt_neo_125_deployment.endpoint_name}"
      slack_webhook_url   = var.slack_webhook_backlog_alerts
    },
    {
      alarm_name          = "high-cpu-alarm-${module.gpt_neo_125_deployment.endpoint_name}"
      alarm_description   = "Scale out when CPU is at 70% threshold"
      metric_name         = "CPUUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "GreaterThanThreshold"
      threshold           = 70 * 8 # TODO: Number of vCPUs
      evaluation_periods  = 1
      datapoints_to_alarm = 1
      period              = 60
      statistic           = "Average"
      alarm_actions       = [module.gpt_neo_125_deployment.scale_up_policy_arn]
      sns_topic_name      = "high-cpu-alert-${module.gpt_neo_125_deployment.endpoint_name}"
      slack_webhook_url   = var.slack_webhook_cpu_alerts
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
      sns_topic_name      = "high-memory-alert-${module.gpt_neo_125_deployment.endpoint_name}"
      slack_webhook_url   = var.slack_webhook_resource_alerts
    },
    {
      alarm_name          = "high-GPU-alarm-${module.gpt_neo_125_deployment.endpoint_name}"
      alarm_description   = "Scale up GPU usage > 70%"
      metric_name         = "GPUUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "GreaterThanThreshold"
      threshold           = 70 * 1 # TODO: Number of GPUs
      evaluation_periods  = 2
      datapoints_to_alarm = 1
      period              = 60
      statistic           = "Average"
      alarm_actions       = [module.gpt_neo_125_deployment.scale_up_policy_arn]
      sns_topic_name      = "high-gpu-alert-${module.gpt_neo_125_deployment.endpoint_name}"
      slack_webhook_url   = var.slack_webhook_gpu_alerts
    },
    {
      alarm_name          = "network-spike-alarm-${module.gpt_neo_125_deployment.endpoint_name}"
      alarm_description   = "Scale up to 1 (deactivated) when endpoint experiences a backlog of requests beyond threshold"
      metric_name         = "ApproximateBacklogSize"
      namespace           = "AWS/SageMaker"
      comparison_operator = "GreaterThanThreshold"
      threshold           = 10
      evaluation_periods  = 2
      datapoints_to_alarm = 2
      period              = 30
      statistic           = "Average"
      sns_topic_name      = "network-spike-alarm-${module.gpt_neo_125_deployment.endpoint_name}"
      slack_webhook_url   = var.slack_webhook_resource_alerts
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
      sns_topic_name      = "disk-util-${module.gpt_neo_125_deployment.endpoint_name}"
      slack_webhook_url   = var.slack_webhook_resource_alerts
    },
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
      sns_topic_name      = "error-rate-high-${module.gpt_neo_125_deployment.endpoint_name}"
      slack_webhook_url   = var.slack_webhook_resource_alerts
    },
    {
      alarm_name          = "unathorized-operations-alarm-${module.gpt_neo_125_deployment.endpoint_name}"
      alarm_description   = "Triggers when unauthorized operations are detected in the CloudTrail Logs"
      metric_name         = "UnauthorizedOperationsCount"
      namespace           = "CloudTrailMetrics"
      comparison_operator = "GreaterThanThreshold"
      threshold           = 1
      evaluation_periods  = 1
      datapoints_to_alarm = 1
      period              = 300
      statistic           = "Sum"
      alarm_actions       = [module.sns.unauthorised_access_sns_topic_arn]
      sns_topic_name      = "unauthorised-operations-${module.gpt_neo_125_deployment.endpoint_name}"
      slack_webhook_url   = var.slack_webhook_security_alerts
    }
  ]
  slack_lambda_name = "slack-integration-${module.gpt_neo_125_deployment.endpoint_name}"
}


###############
# Llama 3.2 1b
###############
module "llama_3_2_1b_deployment" {
  source                 = "./modules/sagemaker_deployment"
  model_name             = "llama-3-2-1b"
  sns_success_topic_arn  = module.sagemaker_output_mover.sns_success_topic_arn
  execution_role_arn     = module.iam.inference_role
  container_image        = "763104351884.dkr.ecr.eu-west-2.amazonaws.com/djl-inference:0.29.0-lmi11.0.0-cu124"
  uncompressed_model_uri = "s3://jumpstart-private-cache-prod-eu-west-2/meta-textgeneration/meta-textgeneration-llama-3-2-1b/artifacts/inference-prepack/v1.0.0/"
  environment_variables = {
    "ENDPOINT_SERVER_TIMEOUT" : "3600",
    "HF_MODEL_ID" : "/opt/ml/model",
    "MODEL_CACHE_ROOT" : "/opt/ml/model",
    "OPTION_ENABLE_CHUNKED_PREFILL" : "true",
    "SAGEMAKER_ENV" : "1",
    "SAGEMAKER_MODEL_SERVER_WORKERS" : "1",
    "SAGEMAKER_PROGRAM" : "inference.py"
  }
  instance_type             = "ml.g6.xlarge" # 4 vCPU and 1 GPU and 16 GB-RAM
  security_group_ids        = [aws_security_group.notebooks.id]
  subnets                   = aws_subnet.private_without_egress.*.id
  endpoint_config_name      = "sagemaker-endpoint-config-llama-3-2-1b"
  endpoint_name             = "llama-3-2-1b-endpoint"
  variant_name              = "llama-3-2-1b-endpoint-dev"
  initial_instance_count    = 1
  s3_output_path            = "https://${module.iam.default_sagemaker_bucket.bucket_regional_domain_name}"
  max_capacity              = 2
  min_capacity              = 0
  scale_up_adjustment       = 1
  scale_up_cooldown         = 30
  scale_in_to_zero_cooldown = 120
  log_group_name            = "/aws/sagemaker/Endpoints/${module.llama_3_2_1b_deployment.endpoint_name}"
  aws_account_id            = data.aws_caller_identity.aws_caller_identity.account_id

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
      sns_topic_name      = "backlog-alarm-${module.llama_3_2_1b_deployment.endpoint_name}"
      slack_webhook_url   = var.slack_webhook_backlog_alerts
    },
    {
      alarm_name          = "low-cpu-alarm-${module.llama_3_2_1b_deployment.endpoint_name}"
      alarm_description   = "Scale in to zero when CPU < 5%"
      metric_name         = "CPUUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "LessThanThreshold"
      threshold           = 5 * 4 # TODO: Number of vCPUs
      evaluation_periods  = 3
      datapoints_to_alarm = 2
      period              = 60
      statistic           = "Average"
      alarm_actions       = [module.llama_3_2_1b_deployment.scale_in_to_zero_policy_arn]
      sns_topic_name      = "low-cpu-alert-${module.llama_3_2_1b_deployment.endpoint_name}"
      slack_webhook_url   = var.slack_webhook_cpu_alerts
    },
    {
      alarm_name          = "no-query-in-backlog-alarm-${module.llama_3_2_1b_deployment.endpoint_name}"
      alarm_description   = "Scale in to zero when no queries are in the backlog for > 3 minutes"
      metric_name         = "ApproximateBacklogSize"
      namespace           = "AWS/SageMaker"
      comparison_operator = "LessThanThreshold"
      threshold           = 0
      evaluation_periods  = 3
      datapoints_to_alarm = 2
      period              = 60
      statistic           = "Sum"
      alarm_actions       = [module.llama_3_2_1b_deployment.scale_in_to_zero_based_on_backlog_arn]
      sns_topic_name      = "no-query-in-backlog-alarm-${module.llama_3_2_1b_deployment.endpoint_name}"
      slack_webhook_url   = var.slack_webhook_backlog_alerts
    },
    {
      alarm_name          = "high-cpu-alarm-${module.llama_3_2_1b_deployment.endpoint_name}"
      alarm_description   = "Scale out when CPU is at 70% threshold"
      metric_name         = "CPUUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "GreaterThanThreshold"
      threshold           = 70 * 4 # TODO: Number of vCPUs
      evaluation_periods  = 1
      datapoints_to_alarm = 1
      period              = 60
      statistic           = "Average"
      alarm_actions       = [module.llama_3_2_1b_deployment.scale_up_policy_arn]
      sns_topic_name      = "high-cpu-alert-${module.llama_3_2_1b_deployment.endpoint_name}"
      slack_webhook_url   = var.slack_webhook_cpu_alerts
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
      sns_topic_name      = "high-memory-alert-${module.llama_3_2_1b_deployment.endpoint_name}"
      slack_webhook_url   = var.slack_webhook_resource_alerts
    },
    {
      alarm_name          = "high-GPU-alarm-${module.llama_3_2_1b_deployment.endpoint_name}"
      alarm_description   = "Scale up GPU usage > 70%"
      metric_name         = "GPUUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "GreaterThanThreshold"
      threshold           = 70 * 1 # TODO: Number of GPUs
      evaluation_periods  = 2
      datapoints_to_alarm = 1
      period              = 60
      statistic           = "Average"
      alarm_actions       = [module.llama_3_2_1b_deployment.scale_up_policy_arn]
      sns_topic_name      = "high-gpu-alert-${module.llama_3_2_1b_deployment.endpoint_name}"
      slack_webhook_url   = var.slack_webhook_gpu_alerts
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
      sns_topic_name      = "network-spike-alarm-${module.llama_3_2_1b_deployment.endpoint_name}"
      slack_webhook_url   = var.slack_webhook_resource_alerts
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
      sns_topic_name      = "dik-util-alarm-${module.llama_3_2_1b_deployment.endpoint_name}"
      slack_webhook_url   = var.slack_webhook_resource_alerts
    },
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
      sns_topic_name      = "High-error-rate-operations-alarm-${module.llama_3_2_1b_deployment.endpoint_name}"
      slack_webhook_url   = var.slack_webhook_resource_alerts
    },
    {
      alarm_name          = "unathorized-operations-alarm-${module.llama_3_2_1b_deployment.endpoint_name}"
      alarm_description   = "Triggers when unauthorized operations are detected in the CloudTrail Logs"
      metric_name         = "UnauthorizedOperationsCount"
      namespace           = "CloudTrailMetrics"
      comparison_operator = "GreaterThanThreshold"
      threshold           = 1
      evaluation_periods  = 1
      datapoints_to_alarm = 1
      period              = 300
      statistic           = "Sum"
      alarm_actions       = [module.sns.unauthorised_access_sns_topic_arn]
      sns_topic_name      = "unauthorised-operations-alarm-${module.llama_3_2_1b_deployment.endpoint_name}"
      slack_webhook_url   = var.slack_webhook_security_alerts
    }
  ]
  slack_lambda_name = "slack-integration-${module.llama_3_2_1b_deployment.endpoint_name}"
}


###############
# Mistral 7b
###############
module "mistral_7b_deployment" {
  source                 = "./modules/sagemaker_deployment"
  model_name             = "mistral-7b"
  sns_success_topic_arn  = module.sagemaker_output_mover.sns_success_topic_arn
  execution_role_arn     = module.iam.inference_role
  container_image        = "763104351884.dkr.ecr.eu-west-2.amazonaws.com/huggingface-pytorch-tgi-inference:2.3.0-tgi2.0.3-gpu-py310-cu121-ubuntu22.04"
  uncompressed_model_uri = "s3://jumpstart-cache-prod-eu-west-2/huggingface-llm/huggingface-llm-mistral-7b-v3/artifacts/inference-prepack/v1.0.0/"
  environment_variables = {
    "ENDPOINT_SERVER_TIMEOUT" : "3600",
    "HF_MODEL_ID" : "/opt/ml/model",
    "MAX_BATCH_PREFILL_TOKENS" : "8191",
    "MAX_INPUT_LENGTH" : "8191",
    "MAX_TOTAL_TOKENS" : "8192",
    "MODEL_CACHE_ROOT" : "/opt/ml/model",
    "SAGEMAKER_ENV" : "1",
    "SAGEMAKER_MODEL_SERVER_WORKERS" : "1",
    "SAGEMAKER_PROGRAM" : "inference.py"
  }
  instance_type             = "ml.g5.12xlarge" # 48 vCPU and 4 GPU and 192 GB-RAM
  security_group_ids        = [aws_security_group.notebooks.id]
  subnets                   = aws_subnet.private_without_egress.*.id
  endpoint_config_name      = "sagemaker-endpoint-config-mistral-7b"
  endpoint_name             = "mistral-7b-endpoint"
  variant_name              = "mistral-7b-endpoint-dev"
  initial_instance_count    = 1
  s3_output_path            = "https://${module.iam.default_sagemaker_bucket.bucket_regional_domain_name}"
  max_capacity              = 2
  min_capacity              = 0
  scale_up_adjustment       = 1
  scale_up_cooldown         = 30
  scale_in_to_zero_cooldown = 120
  log_group_name            = "/aws/sagemaker/Endpoints/${module.mistral_7b_deployment.endpoint_name}"
  aws_account_id            = data.aws_caller_identity.aws_caller_identity.account_id

  alarms = [
    {
      alarm_name          = "backlog-alarm-${module.mistral_7b_deployment.endpoint_name}"
      alarm_description   = "Scale up to 1 when queries are in the backlog, if 0 instances"
      metric_name         = "HasBacklogWithoutCapacity"
      namespace           = "AWS/SageMaker"
      comparison_operator = "GreaterThanOrEqualToThreshold"
      threshold           = 1
      evaluation_periods  = 1
      datapoints_to_alarm = 1
      period              = 30
      statistic           = "Average"
      alarm_actions       = [module.mistral_7b_deployment.scale_up_policy_arn]
      sns_topic_name      = "backlog-alarm-${module.mistral_7b_deployment.endpoint_name}"
      slack_webhook_url   = var.slack_webhook_backlog_alerts
    },
    {
      alarm_name          = "low-cpu-alarm-${module.mistral_7b_deployment.endpoint_name}"
      alarm_description   = "Scale in to zero when CPU < 5%"
      metric_name         = "CPUUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "LessThanThreshold"
      threshold           = 5 * 48 # TODO: Number of vCPUs
      evaluation_periods  = 3
      datapoints_to_alarm = 2
      period              = 60
      statistic           = "Average"
      alarm_actions       = [module.mistral_7b_deployment.scale_in_to_zero_policy_arn]
      sns_topic_name      = "low-cpu-alert-${module.mistral_7b_deployment.endpoint_name}"
      slack_webhook_url   = var.slack_webhook_cpu_alerts
    },
    {
      alarm_name          = "no-query-in-backlog-alarm-${module.mistral_7b_deployment.endpoint_name}"
      alarm_description   = "Scale in to zero when no queries are in the backlog for > 3 minutes"
      metric_name         = "ApproximateBacklogSize"
      namespace           = "AWS/SageMaker"
      comparison_operator = "LessThanThreshold"
      threshold           = 0
      evaluation_periods  = 3
      datapoints_to_alarm = 2
      period              = 60
      statistic           = "Sum"
      alarm_actions       = [module.mistral_7b_deployment.scale_in_to_zero_based_on_backlog_arn]
      sns_topic_name      = "no-query-in-backlog-alarm-${module.mistral_7b_deployment.endpoint_name}"
      slack_webhook_url   = var.slack_webhook_backlog_alerts
    },
    {
      alarm_name          = "high-cpu-alarm-${module.mistral_7b_deployment.endpoint_name}"
      alarm_description   = "Scale out when CPU is at 70% threshold"
      metric_name         = "CPUUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "GreaterThanThreshold"
      threshold           = 70 * 48 # TODO: Number of vCPUs
      evaluation_periods  = 1
      datapoints_to_alarm = 1
      period              = 60
      statistic           = "Average"
      alarm_actions       = [module.mistral_7b_deployment.scale_up_policy_arn]
      sns_topic_name      = "high-cpu-alert-${module.mistral_7b_deployment.endpoint_name}"
      slack_webhook_url   = var.slack_webhook_cpu_alerts
    },
    {
      alarm_name          = "high-memory-alarm-${module.mistral_7b_deployment.endpoint_name}"
      alarm_description   = "Scale up memory usage > 80%"
      metric_name         = "MemoryUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "GreaterThanThreshold"
      threshold           = 80
      evaluation_periods  = 2
      datapoints_to_alarm = 1
      period              = 60
      statistic           = "Average"
      alarm_actions       = [module.mistral_7b_deployment.scale_up_policy_arn]
      sns_topic_name      = "high-memory-alert-${module.mistral_7b_deployment.endpoint_name}"
      slack_webhook_url   = var.slack_webhook_resource_alerts
    },
    {
      alarm_name          = "high-GPU-alarm-${module.mistral_7b_deployment.endpoint_name}"
      alarm_description   = "Scale up GPU usage > 70%"
      metric_name         = "GPUUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "GreaterThanThreshold"
      threshold           = 70 * 4 # TODO: Number of GPUs
      evaluation_periods  = 2
      datapoints_to_alarm = 1
      period              = 60
      statistic           = "Average"
      alarm_actions       = [module.mistral_7b_deployment.scale_up_policy_arn]
      sns_topic_name      = "high-gpu-alert-${module.mistral_7b_deployment.endpoint_name}"
      slack_webhook_url   = var.slack_webhook_gpu_alerts
    },
    {
      alarm_name          = "network-spike-alarm-${module.mistral_7b_deployment.endpoint_name}"
      alarm_description   = "Scale up to 1 (deactivated) when endpoint experiences a backlog of requests beyond threshold"
      metric_name         = "ApproximateBacklogSize"
      namespace           = "AWS/SageMaker"
      comparison_operator = "GreaterThanThreshold"
      threshold           = 10
      evaluation_periods  = 2
      datapoints_to_alarm = 2
      period              = 30
      statistic           = "Average"
      sns_topic_name      = "network-spike-alarm-${module.mistral_7b_deployment.endpoint_name}"
      slack_webhook_url   = var.slack_webhook_resource_alerts
    },
    {
      alarm_name          = "disk-util-alarm-${module.mistral_7b_deployment.endpoint_name}"
      alarm_description   = "Alerts when disk util is high"
      metric_name         = "DiskUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "GreaterThanThreshold"
      threshold           = 80
      evaluation_periods  = 2
      datapoints_to_alarm = 2
      period              = 30
      statistic           = "Average"
      sns_topic_name      = "dik-util-alarm-${module.mistral_7b_deployment.endpoint_name}"
      slack_webhook_url   = var.slack_webhook_resource_alerts
    },
    {
      alarm_name          = "error-rate-high-${module.mistral_7b_deployment.endpoint_name}"
      alarm_description   = "Scales up (deactivated) when Invocation Error rate exceeds 1% over 5 minutes"
      metric_name         = "Invocation4XXErrors"
      namespace           = "AWS/SageMaker"
      comparison_operator = "GreaterThanThreshold"
      threshold           = 200 * 0.01
      evaluation_periods  = 1
      datapoints_to_alarm = 1
      period              = 300
      statistic           = "Sum"
      sns_topic_name      = "High-error-rate-operations-alarm-${module.mistral_7b_deployment.endpoint_name}"
      slack_webhook_url   = var.slack_webhook_resource_alerts
    },
    {
      alarm_name          = "unathorized-operations-alarm-${module.mistral_7b_deployment.endpoint_name}"
      alarm_description   = "Triggers when unauthorized operations are detected in the CloudTrail Logs"
      metric_name         = "UnauthorizedOperationsCount"
      namespace           = "CloudTrailMetrics"
      comparison_operator = "GreaterThanThreshold"
      threshold           = 1
      evaluation_periods  = 1
      datapoints_to_alarm = 1
      period              = 300
      statistic           = "Sum"
      alarm_actions       = [module.sns.unauthorised_access_sns_topic_arn]
      sns_topic_name      = "unauthorised-operations-alarm-${module.mistral_7b_deployment.endpoint_name}"
      slack_webhook_url   = var.slack_webhook_security_alerts
    }
  ]
  slack_lambda_name = "slack-integration-${module.mistral_7b_deployment.endpoint_name}"
}


###############
# Gemma 2 27b
###############
module "gemma_2_27b_deployment" {
  source                 = "./modules/sagemaker_deployment"
  model_name             = "gemma-2-27b"
  sns_success_topic_arn  = module.sagemaker_output_mover.sns_success_topic_arn
  execution_role_arn     = module.iam.inference_role
  container_image        = "763104351884.dkr.ecr.eu-west-2.amazonaws.com/huggingface-pytorch-tgi-inference:2.4.0-tgi2.3.1-gpu-py311-cu124-ubuntu22.04"
  uncompressed_model_uri = "s3://jumpstart-private-cache-prod-eu-west-2/huggingface-llm/huggingface-llm-gemma-2-27b/artifacts/inference-prepack/v1.0.0/"
  environment_variables = {
    "ENDPOINT_SERVER_TIMEOUT" : "3600",
    "HF_MODEL_ID" : "/opt/ml/model",
    "MAX_BATCH_PREFILL_TOKENS" : "8191",
    "MAX_INPUT_LENGTH" : "8191",
    "MAX_TOTAL_TOKENS" : "8192",
    "MODEL_CACHE_ROOT" : "/opt/ml/model",
    "SAGEMAKER_PROGRAM" : "inference.py",
    "SM_NUM_GPUS" : "8"
  }
  instance_type             = "ml.g5.48xlarge" # 192 vCPU and 8 GPU and 768 GB-RAM
  security_group_ids        = [aws_security_group.notebooks.id]
  subnets                   = aws_subnet.private_without_egress.*.id
  endpoint_config_name      = "sagemaker-endpoint-config-gemma-2-27b"
  endpoint_name             = "gemma-2-27b-endpoint"
  variant_name              = "gemma-2-27b-endpoint-dev"
  initial_instance_count    = 1
  s3_output_path            = "https://${module.iam.default_sagemaker_bucket.bucket_regional_domain_name}"
  max_capacity              = 2
  min_capacity              = 0
  scale_up_adjustment       = 1
  scale_up_cooldown         = 30
  scale_in_to_zero_cooldown = 120
  log_group_name            = "/aws/sagemaker/Endpoints/${module.gemma_2_27b_deployment.endpoint_name}"
  aws_account_id            = data.aws_caller_identity.aws_caller_identity.account_id

  alarms = [
    {
      alarm_name          = "backlog-alarm-${module.gemma_2_27b_deployment.endpoint_name}"
      alarm_description   = "Scale up to 1 when queries are in the backlog, if 0 instances"
      metric_name         = "HasBacklogWithoutCapacity"
      namespace           = "AWS/SageMaker"
      comparison_operator = "GreaterThanOrEqualToThreshold"
      threshold           = 1
      evaluation_periods  = 1
      datapoints_to_alarm = 1
      period              = 30
      statistic           = "Average"
      alarm_actions       = [module.gemma_2_27b_deployment.scale_up_policy_arn]
      sns_topic_name      = "backlog-alarm-${module.gemma_2_27b_deployment.endpoint_name}"
      slack_webhook_url   = var.slack_webhook_backlog_alerts
    },
    {
      alarm_name          = "low-cpu-alarm-${module.gemma_2_27b_deployment.endpoint_name}"
      alarm_description   = "Scale in to zero when CPU < 5%"
      metric_name         = "CPUUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "LessThanThreshold"
      threshold           = 5 * 192 # TODO: Number of vCPUs
      evaluation_periods  = 3
      datapoints_to_alarm = 2
      period              = 60
      statistic           = "Average"
      alarm_actions       = [module.gemma_2_27b_deployment.scale_in_to_zero_policy_arn]
      sns_topic_name      = "low-cpu-alert-${module.gemma_2_27b_deployment.endpoint_name}"
      slack_webhook_url   = var.slack_webhook_cpu_alerts
    },
    {
      alarm_name          = "no-query-in-backlog-alarm-${module.gemma_2_27b_deployment.endpoint_name}"
      alarm_description   = "Scale in to zero when no queries are in the backlog for > 3 minutes"
      metric_name         = "ApproximateBacklogSize"
      namespace           = "AWS/SageMaker"
      comparison_operator = "LessThanThreshold"
      threshold           = 0
      evaluation_periods  = 3
      datapoints_to_alarm = 2
      period              = 60
      statistic           = "Sum"
      alarm_actions       = [module.gemma_2_27b_deployment.scale_in_to_zero_based_on_backlog_arn]
      sns_topic_name      = "no-query-in-backlog-alarm-${module.gemma_2_27b_deployment.endpoint_name}"
      slack_webhook_url   = var.slack_webhook_backlog_alerts
    },
    {
      alarm_name          = "high-cpu-alarm-${module.gemma_2_27b_deployment.endpoint_name}"
      alarm_description   = "Scale out when CPU is at 70% threshold"
      metric_name         = "CPUUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "GreaterThanThreshold"
      threshold           = 70 * 192 # TODO: Number of vCPUs
      evaluation_periods  = 1
      datapoints_to_alarm = 1
      period              = 60
      statistic           = "Average"
      alarm_actions       = [module.gemma_2_27b_deployment.scale_up_policy_arn]
      sns_topic_name      = "high-cpu-alert-${module.gemma_2_27b_deployment.endpoint_name}"
      slack_webhook_url   = var.slack_webhook_cpu_alerts
    },
    {
      alarm_name          = "high-memory-alarm-${module.gemma_2_27b_deployment.endpoint_name}"
      alarm_description   = "Scale up memory usage > 80%"
      metric_name         = "MemoryUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "GreaterThanThreshold"
      threshold           = 80
      evaluation_periods  = 2
      datapoints_to_alarm = 1
      period              = 60
      statistic           = "Average"
      alarm_actions       = [module.gemma_2_27b_deployment.scale_up_policy_arn]
      sns_topic_name      = "high-memory-alert-${module.gemma_2_27b_deployment.endpoint_name}"
      slack_webhook_url   = var.slack_webhook_resource_alerts
    },
    {
      alarm_name          = "high-GPU-alarm-${module.gemma_2_27b_deployment.endpoint_name}"
      alarm_description   = "Scale up GPU usage > 70%"
      metric_name         = "GPUUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "GreaterThanThreshold"
      threshold           = 70 * 8 # TODO: Number of GPUs
      evaluation_periods  = 2
      datapoints_to_alarm = 1
      period              = 60
      statistic           = "Average"
      alarm_actions       = [module.gemma_2_27b_deployment.scale_up_policy_arn]
      sns_topic_name      = "high-gpu-alert-${module.gemma_2_27b_deployment.endpoint_name}"
      slack_webhook_url   = var.slack_webhook_gpu_alerts
    },
    {
      alarm_name          = "network-spike-alarm-${module.gemma_2_27b_deployment.endpoint_name}"
      alarm_description   = "Scale up to 1 (deactivated) when endpoint experiences a backlog of requests beyond threshold"
      metric_name         = "ApproximateBacklogSize"
      namespace           = "AWS/SageMaker"
      comparison_operator = "GreaterThanThreshold"
      threshold           = 10
      evaluation_periods  = 2
      datapoints_to_alarm = 2
      period              = 30
      statistic           = "Average"
      sns_topic_name      = "network-spike-alarm-${module.gemma_2_27b_deployment.endpoint_name}"
      slack_webhook_url   = var.slack_webhook_resource_alerts
    },
    {
      alarm_name          = "disk-util-alarm-${module.gemma_2_27b_deployment.endpoint_name}"
      alarm_description   = "Alerts when disk util is high"
      metric_name         = "DiskUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "GreaterThanThreshold"
      threshold           = 80
      evaluation_periods  = 2
      datapoints_to_alarm = 2
      period              = 30
      statistic           = "Average"
      sns_topic_name      = "dik-util-alarm-${module.gemma_2_27b_deployment.endpoint_name}"
      slack_webhook_url   = var.slack_webhook_resource_alerts
    },
    {
      alarm_name          = "error-rate-high-${module.gemma_2_27b_deployment.endpoint_name}"
      alarm_description   = "Scales up (deactivated) when Invocation Error rate exceeds 1% over 5 minutes"
      metric_name         = "Invocation4XXErrors"
      namespace           = "AWS/SageMaker"
      comparison_operator = "GreaterThanThreshold"
      threshold           = 200 * 0.01
      evaluation_periods  = 1
      datapoints_to_alarm = 1
      period              = 300
      statistic           = "Sum"
      sns_topic_name      = "High-error-rate-operations-alarm-${module.gemma_2_27b_deployment.endpoint_name}"
      slack_webhook_url   = var.slack_webhook_resource_alerts
    },
    {
      alarm_name          = "unathorized-operations-alarm-${module.gemma_2_27b_deployment.endpoint_name}"
      alarm_description   = "Triggers when unauthorized operations are detected in the CloudTrail Logs"
      metric_name         = "UnauthorizedOperationsCount"
      namespace           = "CloudTrailMetrics"
      comparison_operator = "GreaterThanThreshold"
      threshold           = 1
      evaluation_periods  = 1
      datapoints_to_alarm = 1
      period              = 300
      statistic           = "Sum"
      alarm_actions       = [module.sns.unauthorised_access_sns_topic_arn]
      sns_topic_name      = "unauthorised-operations-alarm-${module.gemma_2_27b_deployment.endpoint_name}"
      slack_webhook_url   = var.slack_webhook_security_alerts
    }
  ]
  slack_lambda_name = "slack-integration-${module.gemma_2_27b_deployment.endpoint_name}"
}



###############
# Llama 3 70b
###############

module "llama_3_70b_deployment" {
  source                 = "./modules/sagemaker_deployment"
  model_name             = "llama-3-70b"
  sns_success_topic_arn  = module.sagemaker_output_mover.sns_success_topic_arn
  execution_role_arn     = module.iam.inference_role
  container_image        = "763104351884.dkr.ecr.eu-west-2.amazonaws.com/djl-inference:0.29.0-lmi11.0.0-cu124"
  uncompressed_model_uri = "s3://jumpstart-private-cache-prod-eu-west-2/meta-textgeneration/meta-textgeneration-llama-3-1-70b-instruct/artifacts/inference-prepack/v2.0.0/"
  environment_variables = {
            "ENDPOINT_SERVER_TIMEOUT": "3600",
            "HF_MODEL_ID": "/opt/ml/model",
            "MODEL_CACHE_ROOT": "/opt/ml/model",
            "OPTION_ENFORCE_EAGER": "true",
            "OPTION_SPECULATIVE_DRAFT_MODEL": "/opt/ml/additional-model-data-sources/draft_model",
            "OPTION_TENSOR_PARALLEL_DEGREE": "8",
            "SAGEMAKER_ENV": "1",
            "SAGEMAKER_MODEL_SERVER_WORKERS": "1",
            "SAGEMAKER_PROGRAM": "inference.py"
        }
  instance_type             = "ml.p4d.24xlarge"  # 96 vCPU and 8 GPU and 1152 GB-RAM
  security_group_ids        = [aws_security_group.notebooks.id]
  subnets                   = aws_subnet.private_without_egress.*.id
  endpoint_config_name      = "sagemaker-endpoint-config-llama-3-70b"
  endpoint_name             = "llama-3-70b-endpoint"
  variant_name              = "llama-3-70b-endpoint-dev"
  initial_instance_count    = 1
  s3_output_path            = "https://${module.iam.default_sagemaker_bucket.bucket_regional_domain_name}"
  max_capacity              = 2
  min_capacity              = 0
  scale_up_adjustment       = 1
  scale_up_cooldown         = 30
  scale_in_to_zero_cooldown = 120
  log_group_name            = "/aws/sagemaker/Endpoints/${module.llama_3_70b_deployment.endpoint_name}"
  aws_account_id            = data.aws_caller_identity.aws_caller_identity.account_id

  alarms = [
    {
      alarm_name          = "backlog-alarm-${module.llama_3_70b_deployment.endpoint_name}"
      alarm_description   = "Scale up to 1 when queries are in the backlog, if 0 instances"
      metric_name         = "HasBacklogWithoutCapacity"
      namespace           = "AWS/SageMaker"
      comparison_operator = "GreaterThanOrEqualToThreshold"
      threshold           = 1
      evaluation_periods  = 1
      datapoints_to_alarm = 1
      period              = 30
      statistic           = "Average"
      alarm_actions       = [module.llama_3_70b_deployment.scale_up_policy_arn]
      sns_topic_name      = "backlog-alarm-${module.llama_3_70b_deployment.endpoint_name}"
      slack_webhook_url   = var.slack_webhook_backlog_alerts
    },
    {
      alarm_name          = "low-cpu-alarm-${module.llama_3_70b_deployment.endpoint_name}"
      alarm_description   = "Scale in to zero when CPU < 5%"
      metric_name         = "CPUUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "LessThanThreshold"
      threshold           = 5 * 96  # TODO: Number of vCPUs
      evaluation_periods  = 3
      datapoints_to_alarm = 2
      period              = 60
      statistic           = "Average"
      alarm_actions       = [module.llama_3_70b_deployment.scale_in_to_zero_policy_arn]
      sns_topic_name      = "low-cpu-alert-${module.llama_3_70b_deployment.endpoint_name}"
      slack_webhook_url   = var.slack_webhook_cpu_alerts
    },
    {
      alarm_name          = "no-query-in-backlog-alarm-${module.llama_3_70b_deployment.endpoint_name}"
      alarm_description   = "Scale in to zero when no queries are in the backlog for > 3 minutes"
      metric_name         = "ApproximateBacklogSize"
      namespace           = "AWS/SageMaker"
      comparison_operator = "LessThanThreshold"
      threshold           = 0
      evaluation_periods  = 3
      datapoints_to_alarm = 2
      period              = 60
      statistic           = "Sum"
      alarm_actions       = [module.llama_3_70b_deployment.scale_in_to_zero_based_on_backlog_arn]
      sns_topic_name      = "no-query-in-backlog-alarm-${module.llama_3_70b_deployment.endpoint_name}"
      slack_webhook_url   = var.slack_webhook_backlog_alerts
    },
    {
      alarm_name          = "high-cpu-alarm-${module.llama_3_70b_deployment.endpoint_name}"
      alarm_description   = "Scale out when CPU is at 70% threshold"
      metric_name         = "CPUUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "GreaterThanThreshold"
      threshold           = 70 * 96  # TODO: Number of vCPUs
      evaluation_periods  = 1
      datapoints_to_alarm = 1
      period              = 60
      statistic           = "Average"
      alarm_actions       = [module.llama_3_70b_deployment.scale_up_policy_arn]
      sns_topic_name      = "high-cpu-alert-${module.llama_3_70b_deployment.endpoint_name}"
      slack_webhook_url   = var.slack_webhook_cpu_alerts
    },
    {
      alarm_name          = "high-memory-alarm-${module.llama_3_70b_deployment.endpoint_name}"
      alarm_description   = "Scale up memory usage > 80%"
      metric_name         = "MemoryUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "GreaterThanThreshold"
      threshold           = 80
      evaluation_periods  = 2
      datapoints_to_alarm = 1
      period              = 60
      statistic           = "Average"
      alarm_actions       = [module.llama_3_70b_deployment.scale_up_policy_arn]
      sns_topic_name      = "high-memory-alert-${module.llama_3_70b_deployment.endpoint_name}"
      slack_webhook_url   = var.slack_webhook_resource_alerts
    },
    {
      alarm_name          = "high-GPU-alarm-${module.llama_3_70b_deployment.endpoint_name}"
      alarm_description   = "Scale up GPU usage > 70%"
      metric_name         = "GPUUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "GreaterThanThreshold"
      threshold           = 70 * 8  # TODO: Number of GPUs
      evaluation_periods  = 2
      datapoints_to_alarm = 1
      period              = 60
      statistic           = "Average"
      alarm_actions       = [module.llama_3_70b_deployment.scale_up_policy_arn]
      sns_topic_name      = "high-gpu-alert-${module.llama_3_70b_deployment.endpoint_name}"
      slack_webhook_url   = var.slack_webhook_gpu_alerts
    },
    {
      alarm_name          = "network-spike-alarm-${module.llama_3_70b_deployment.endpoint_name}"
      alarm_description   = "Scale up to 1 (deactivated) when endpoint experiences a backlog of requests beyond threshold"
      metric_name         = "ApproximateBacklogSize"
      namespace           = "AWS/SageMaker"
      comparison_operator = "GreaterThanThreshold"
      threshold           = 10
      evaluation_periods  = 2
      datapoints_to_alarm = 2
      period              = 30
      statistic           = "Average"
      sns_topic_name      = "network-spike-alarm-${module.llama_3_70b_deployment.endpoint_name}"
      slack_webhook_url   = var.slack_webhook_resource_alerts
    },
    {
      alarm_name          = "disk-util-alarm-${module.llama_3_70b_deployment.endpoint_name}"
      alarm_description   = "Alerts when disk util is high"
      metric_name         = "DiskUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "GreaterThanThreshold"
      threshold           = 80
      evaluation_periods  = 2
      datapoints_to_alarm = 2
      period              = 30
      statistic           = "Average"
      sns_topic_name      = "dik-util-alarm-${module.llama_3_70b_deployment.endpoint_name}"
      slack_webhook_url   = var.slack_webhook_resource_alerts
    },
    {
      alarm_name          = "error-rate-high-${module.llama_3_70b_deployment.endpoint_name}"
      alarm_description   = "Scales up (deactivated) when Invocation Error rate exceeds 1% over 5 minutes"
      metric_name         = "Invocation4XXErrors"
      namespace           = "AWS/SageMaker"
      comparison_operator = "GreaterThanThreshold"
      threshold           = 200 * 0.01
      evaluation_periods  = 1
      datapoints_to_alarm = 1
      period              = 300
      statistic           = "Sum"
      sns_topic_name      = "High-error-rate-operations-alarm-${module.llama_3_70b_deployment.endpoint_name}"
      slack_webhook_url   = var.slack_webhook_resource_alerts
    },
    {
      alarm_name          = "unathorized-operations-alarm-${module.llama_3_70b_deployment.endpoint_name}"
      alarm_description   = "Triggers when unauthorized operations are detected in the CloudTrail Logs"
      metric_name         = "UnauthorizedOperationsCount"
      namespace           = "CloudTrailMetrics"
      comparison_operator = "GreaterThanThreshold"
      threshold           = 1
      evaluation_periods  = 1
      datapoints_to_alarm = 1
      period              = 300
      statistic           = "Sum"
      alarm_actions       = [module.sns.unauthorised_access_sns_topic_arn]
      sns_topic_name      = "unauthorised-operations-alarm-${module.llama_3_70b_deployment.endpoint_name}"
      slack_webhook_url   = var.slack_webhook_security_alerts
    }
  ]
  slack_lambda_name = "slack-integration-${module.llama_3_70b_deployment.endpoint_name}"
}
