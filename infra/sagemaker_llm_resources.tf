# TODO: better if this is not required to be stated explicitly as it is brittle
locals {
  all_llm_names = [
    module.phi_2_3b_deployment[0].model_name,
  ]
}

###############
# Phi 2 3b
###############
module "phi_2_3b_deployment" {

  count = (var.sagemaker_on && var.sagemaker_phi_2_3b) ? 1 : 0

  model_name            = "phi-2-3b"
  container_image       = "763104351884.dkr.ecr.eu-west-2.amazonaws.com/huggingface-pytorch-tgi-inference:2.1.1-tgi1.4.2-gpu-py310-cu121-ubuntu22.04"
  model_uri             = "s3://jumpstart-cache-prod-eu-west-2/huggingface-llm/huggingface-llm-phi-2/artifacts/inference-prepack/v1.0.0/"
  model_uri_compression = "None"
  instance_type         = "ml.g5.xlarge" # 4 vCPU and 1 GPU and 16 GB-RAM
  max_capacity          = 2
  min_capacity          = 0
  scale_up_cooldown     = 900
  scale_down_cooldown   = 0
  environment_variables = {
    "ENDPOINT_SERVER_TIMEOUT" : "3600",
    "HF_MODEL_ID" : "/opt/ml/model",
    "MAX_INPUT_LENGTH" : "2047",
    "MAX_TOTAL_TOKENS" : "2048",
    "MODEL_CACHE_ROOT" : "/opt/ml/model",
    "SAGEMAKER_ENV" : "1",
    "SAGEMAKER_MODEL_SERVER_WORKERS" : "1",
    "SAGEMAKER_PROGRAM" : "inference.py"
  }

  alarms = [
    {
      alarm_name_prefix   = "nonzero-backlog" # TODO: backlog is currently required to have index [0,1] which is brittle
      alarm_description   = "Scale up based on existence of backlog"
      metric_name         = "ApproximateBacklogSize"
      namespace           = "AWS/SageMaker"
      comparison_operator = "GreaterThanOrEqualToThreshold"
      threshold           = 1
      evaluation_periods  = 1
      datapoints_to_alarm = 1
      period              = 60
      statistic           = "Maximum"
      slack_webhook_url   = var.slack_webhook_backlog_alerts
      alarm_actions       = [module.phi_2_3b_deployment[0].scale_up_to_one_policy_arn]
      ok_actions          = []
    },
    {
      alarm_name_prefix   = "zero-backlog" # TODO: backlog is currently required to have index [0,1] which is brittle
      alarm_description   = "Scale down based on non-existence of backlog"
      metric_name         = "ApproximateBacklogSize"
      namespace           = "AWS/SageMaker"
      comparison_operator = "LessThanThreshold"
      threshold           = 1
      evaluation_periods  = 15
      datapoints_to_alarm = 15
      period              = 60
      statistic           = "Maximum"
      slack_webhook_url   = var.slack_webhook_backlog_alerts
      alarm_actions       = [module.phi_2_3b_deployment[0].scale_down_to_zero_policy_arn]
      ok_actions          = []
    },
    {
      alarm_name_prefix   = "backlog-composite-alarm"
      alarm_description   = "Detect if queries in backlog for extended time period"
      metric_name         = "ApproximateBacklogSize"
      namespace           = "AWS/SageMaker"
      comparison_operator = "LessThanOrEqualToThreshold"
      threshold           = 0
      evaluation_periods  = 3
      datapoints_to_alarm = 3
      period              = 3600
      statistic           = "Average"
      slack_webhook_url   = var.slack_webhook_backlog_alerts
      alarm_actions       = []
      ok_actions          = []
    },
    {
      alarm_name_prefix   = "high-cpu"
      alarm_description   = "Scale up when CPU usage is heavy"
      metric_name         = "CPUUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "GreaterThanOrEqualToThreshold"
      threshold           = 80 * 4 # TODO: we must manually multiply by vCPU count as Normalized metric not available
      evaluation_periods  = 1
      datapoints_to_alarm = 1
      period              = 60
      statistic           = "Maximum"
      slack_webhook_url   = var.slack_webhook_cpu_alerts
      alarm_actions       = [module.phi_2_3b_deployment[0].scale_up_to_n_policy_arn]
      ok_actions          = []
    },
    {
      alarm_name_prefix   = "low-cpu"
      alarm_description   = "Scale down when CPU usage is light"
      metric_name         = "CPUUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "LessThanOrEqualToThreshold"
      threshold           = 20 * 4 # TODO: we must manually multiply by vCPU count as Normalized metric not available
      evaluation_periods  = 15
      datapoints_to_alarm = 15
      period              = 60
      statistic           = "Maximum"
      slack_webhook_url   = var.slack_webhook_cpu_alerts
      alarm_actions       = [module.phi_2_3b_deployment[0].scale_down_to_n_policy_arn]
      ok_actions          = []
    },
    {
      alarm_name_prefix   = "high-gpu"
      alarm_description   = "Scale up when GPU usage is heavy"
      metric_name         = "GPUUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "GreaterThanOrEqualToThreshold"
      threshold           = 80 * 1 # TODO: we must manually multiply by GPU count as Normalized metric not available
      evaluation_periods  = 1
      datapoints_to_alarm = 1
      period              = 60
      statistic           = "Maximum"
      slack_webhook_url   = var.slack_webhook_gpu_alerts
      alarm_actions       = [module.phi_2_3b_deployment[0].scale_up_to_n_policy_arn]
      ok_actions          = []
    },
    {
      alarm_name_prefix   = "low-gpu"
      alarm_description   = "Scale down when GPU usage is light"
      metric_name         = "GPUUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "LessThanOrEqualToThreshold"
      threshold           = 20 * 1 # TODO: we must manually multiply by GPU count as Normalized metric not available
      evaluation_periods  = 15
      datapoints_to_alarm = 15
      period              = 60
      statistic           = "Maximum"
      slack_webhook_url   = var.slack_webhook_gpu_alerts
      alarm_actions       = [module.phi_2_3b_deployment[0].scale_down_to_n_policy_arn]
      ok_actions          = []
    },
    {
      alarm_name_prefix   = "high-ram"
      alarm_description   = "Scale up when RAM usage is heavy"
      metric_name         = "MemoryUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "GreaterThanOrEqualToThreshold"
      threshold           = 80
      evaluation_periods  = 1
      datapoints_to_alarm = 1
      period              = 60
      statistic           = "Maximum"
      slack_webhook_url   = var.slack_webhook_resource_alerts
      alarm_actions       = [module.phi_2_3b_deployment[0].scale_up_to_n_policy_arn]
      ok_actions          = []
    },
    {
      alarm_name_prefix   = "low-ram"
      alarm_description   = "Scale down when RAM usage is light"
      metric_name         = "MemoryUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "LessThanOrEqualToThreshold"
      threshold           = 20
      evaluation_periods  = 15
      datapoints_to_alarm = 15
      period              = 60
      statistic           = "Maximum"
      slack_webhook_url   = var.slack_webhook_resource_alerts
      alarm_actions       = [module.phi_2_3b_deployment[0].scale_down_to_n_policy_arn]
      ok_actions          = []
    },
    {
      alarm_name_prefix   = "high-hard-disk"
      alarm_description   = "Scale up when Hard Disk usage is heavy"
      metric_name         = "DiskUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "GreaterThanOrEqualToThreshold"
      threshold           = 80
      evaluation_periods  = 1
      datapoints_to_alarm = 1
      period              = 60
      statistic           = "Maximum"
      slack_webhook_url   = var.slack_webhook_resource_alerts
      alarm_actions       = [module.phi_2_3b_deployment[0].scale_up_to_n_policy_arn]
      ok_actions          = []
    },
    {
      alarm_name_prefix   = "low-hard-disk"
      alarm_description   = "Scale down when Hard Disk usage is light"
      metric_name         = "DiskUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "LessThanOrEqualToThreshold"
      threshold           = 20
      evaluation_periods  = 15
      datapoints_to_alarm = 15
      period              = 60
      statistic           = "Maximum"
      slack_webhook_url   = var.slack_webhook_resource_alerts
      alarm_actions       = [module.phi_2_3b_deployment[0].scale_down_to_n_policy_arn]
      ok_actions          = []
    },
    {
      alarm_name_prefix   = "unauthorized-operations"
      alarm_description   = "Unauthorized operations are detected in the CloudTrail Logs"
      metric_name         = "UnauthorizedOperationsCount"
      namespace           = "CloudTrailMetrics"
      comparison_operator = "GreaterThanOrEqualToThreshold"
      threshold           = 1
      evaluation_periods  = 1
      datapoints_to_alarm = 1
      period              = 60
      statistic           = "Sum"
      slack_webhook_url   = var.slack_webhook_security_alerts
      alarm_actions       = [] # SNS to give alert to developers
      ok_actions          = []
    },
    {
      alarm_name_prefix   = "errors-4XX"
      alarm_description   = "4XX errors are detected in the CloudTrail Logs"
      metric_name         = "Invocation4XXErrors"
      namespace           = "AWS/SageMaker"
      comparison_operator = "GreaterThanOrEqualToThreshold"
      threshold           = 1
      evaluation_periods  = 1
      datapoints_to_alarm = 1
      period              = 60
      statistic           = "Sum"
      slack_webhook_url   = var.slack_webhook_security_alerts
      alarm_actions       = [] # SNS to give alert to developers
      ok_actions          = []
    },
    {
      alarm_name_prefix   = "elevated-cpu-composite"
      alarm_description   = "Detect CPU activity above idle for extended time period"
      metric_name         = "CPUUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "GreaterThanOrEqualToThreshold"
      threshold           = 20 * 4 # TODO: we must manually multiply by CPU count as Normalized metric not available
      evaluation_periods  = 3
      datapoints_to_alarm = 3
      period              = 3600
      statistic           = "Average"
      slack_webhook_url   = var.slack_webhook_cpu_alerts
      alarm_actions       = []
      ok_actions          = []
    },
    {
      alarm_name_prefix   = "low-gpu-composite"
      alarm_description   = "Scale down when GPU usage is light"
      metric_name         = "GPUUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "GreaterThanOrEqualToThreshold"
      threshold           = 20 * 1 # TODO: we must manually multiply by GPU count as Normalized metric not available
      evaluation_periods  = 3
      datapoints_to_alarm = 3
      period              = 3600
      statistic           = "Average"
      slack_webhook_url   = var.slack_webhook_gpu_alerts
      alarm_actions       = []
      ok_actions          = []
    }
  ]

  alarm_composites = [
    {
      alarm_name        = "ElevatedCPUUtilizationNoBackLog"
      alarm_description = "Triggered when CPU util is above idle and no backlog query exists for an extended time"
      alarm_rule        = "ALARM(elevated-cpu-composite-${module.phi_2_3b_deployment[0].model_name}-endpoint) AND ALARM(backlog-composite-alarm-${module.phi_2_3b_deployment[0].model_name}-endpoint)"
      alarm_actions     = []
      ok_actions        = []
      slack_webhook_url = var.slack_webhook_backlog_alerts
      emails            = var.sagemaker_budget_emails
    },
    {
      alarm_name        = "ElevatedGPUUtilizationNoBackLog"
      alarm_description = "Triggered when GPU util is above idle and no backlog query exists for an extended time"
      alarm_rule        = "ALARM(low-gpu-composite-${module.phi_2_3b_deployment[0].model_name}-endpoint) AND ALARM(backlog-composite-alarm-${module.phi_2_3b_deployment[0].model_name}-endpoint)"
      alarm_actions     = []
      ok_actions        = []
      slack_webhook_url = var.slack_webhook_backlog_alerts
      emails            = var.sagemaker_budget_emails
    }

  ]

  # These variables do not change between LLMs
  source                = "./modules/sagemaker_deployment"
  security_group_ids    = [aws_security_group.sagemaker[0].id, aws_security_group.sagemaker_endpoints[0].id]
  subnets               = aws_subnet.sagemaker_private_without_egress.*.id
  s3_output_path        = "https://${module.iam[0].default_sagemaker_bucket.bucket_regional_domain_name}"
  aws_account_id        = data.aws_caller_identity.aws_caller_identity.account_id
  sns_success_topic_arn = module.sagemaker_output_mover[0].sns_success_topic_arn
  execution_role_arn    = module.iam[0].inference_role
}