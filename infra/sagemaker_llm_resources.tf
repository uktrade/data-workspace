# TODO: better if this is not required to be stated explicitly as it is brittle
locals {
  all_llm_names = [
    module.gpt_neo_125m_deployment.model_name,
    module.phi_2_3b_deployment.model_name,
    module.mistral_7b_deployment.model_name,
    module.gemma_2_27b_deployment.model_name,
    module.llama_3_70b_deployment.model_name,
    #module.falcon_bf16_180b_deployment.model_name,
  ]
}

################
# GPT Neo 125m
###############
module "gpt_neo_125m_deployment" {
  model_name            = "gpt-neo-125m"
  container_image       = "763104351884.dkr.ecr.eu-west-2.amazonaws.com/huggingface-pytorch-tgi-inference:2.1.1-tgi1.4.0-gpu-py310-cu121-ubuntu20.04"
  model_uri             = "s3://jumpstart-cache-prod-eu-west-2/huggingface-textgeneration1/huggingface-textgeneration1-gpt-neo-125m/artifacts/inference-prepack/v2.0.0/"
  model_uri_compression = "None"
  instance_type         = "ml.g5.2xlarge" # 8 vCPU and 1 GPU and 32 GB-RAM
  max_capacity          = 2
  min_capacity          = 0
  scale_up_cooldown     = 0
  scale_down_cooldown   = 0
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

  alarms = [
    {
      alarm_name_prefix   = "backlog"  # TODO: backlog is currently required to have index 0, which is brittle
      alarm_description   = "Scale based on existence of backlog or not"
      metric_name         = "ApproximateBacklogSize"
      namespace           = "AWS/SageMaker"
      comparison_operator = "GreaterThanOrEqualToThreshold"
      threshold           = 1
      evaluation_periods  = 1
      datapoints_to_alarm = 1
      period              = 60
      statistic           = "Maximum"
      slack_webhook_url   = var.slack_webhook_backlog_alerts
      alarm_actions       = [module.gpt_neo_125m_deployment.scale_up_to_one_policy_arn]
      ok_actions          = [module.gpt_neo_125m_deployment.scale_down_to_zero_policy_arn]
    },
    {
      alarm_name_prefix   = "high-cpu"
      alarm_description   = "Scale up when CPU usage is heavy"
      metric_name         = "CPUUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "GreaterThanOrEqualToThreshold"
      threshold           = 80 * 8  # TODO: we must manually multiply by vCPU count as Normalized metric not available
      evaluation_periods  = 1
      datapoints_to_alarm = 1
      period              = 60
      statistic           = "Maximum"
      slack_webhook_url   = var.slack_webhook_cpu_alerts
      alarm_actions       = [module.gpt_neo_125m_deployment.scale_up_to_n_policy_arn]
      ok_actions          = []
    },
    {
      alarm_name_prefix   = "low-cpu"
      alarm_description   = "Scale down when CPU usage is light"
      metric_name         = "CPUUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "LessThanOrEqualToThreshold"
      threshold           = 20 * 8  # TODO: we must manually multiply by vCPU count as Normalized metric not available
      evaluation_periods  = 1
      datapoints_to_alarm = 1
      period              = 60
      statistic           = "Maximum"
      slack_webhook_url   = var.slack_webhook_cpu_alerts
      alarm_actions       = [module.gpt_neo_125m_deployment.scale_down_to_n_policy_arn]
      ok_actions          = []
    },
    {
      alarm_name_prefix   = "high-gpu"
      alarm_description   = "Scale up when GPU usage is heavy"
      metric_name         = "GPUUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "GreaterThanOrEqualToThreshold"
      threshold           = 80 * 1  # TODO: we must manually multiply by GPU count as Normalized metric not available
      evaluation_periods  = 1
      datapoints_to_alarm = 1
      period              = 60
      statistic           = "Maximum"
      slack_webhook_url   = var.slack_webhook_gpu_alerts
      alarm_actions       = [module.gpt_neo_125m_deployment.scale_up_to_n_policy_arn]
      ok_actions          = []
    },
    {
      alarm_name_prefix   = "low-gpu"
      alarm_description   = "Scale down when GPU usage is light"
      metric_name         = "GPUUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "LessThanOrEqualToThreshold"
      threshold           = 20 * 1  # TODO: we must manually multiply by GPU count as Normalized metric not available
      evaluation_periods  = 1
      datapoints_to_alarm = 1
      period              = 60
      statistic           = "Maximum"
      slack_webhook_url   = var.slack_webhook_gpu_alerts
      alarm_actions       = [module.gpt_neo_125m_deployment.scale_down_to_n_policy_arn]
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
      alarm_actions       = [module.gpt_neo_125m_deployment.scale_up_to_n_policy_arn]
      ok_actions          = []
    },
    {
      alarm_name_prefix   = "low-ram"
      alarm_description   = "Scale down when RAM usage is light"
      metric_name         = "MemoryUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "LessThanOrEqualToThreshold"
      threshold           = 20
      evaluation_periods  = 1
      datapoints_to_alarm = 1
      period              = 60
      statistic           = "Maximum"
      slack_webhook_url   = var.slack_webhook_resource_alerts
      alarm_actions       = [module.gpt_neo_125m_deployment.scale_down_to_n_policy_arn]
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
      alarm_actions       = [module.gpt_neo_125m_deployment.scale_up_to_n_policy_arn]
      ok_actions          = []
    },
    {
      alarm_name_prefix   = "low-hard-disk"
      alarm_description   = "Scale down when Hard Disk usage is light"
      metric_name         = "DiskUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "LessThanOrEqualToThreshold"
      threshold           = 20
      evaluation_periods  = 1
      datapoints_to_alarm = 1
      period              = 60
      statistic           = "Maximum"
      slack_webhook_url   = var.slack_webhook_resource_alerts
      alarm_actions       = [module.gpt_neo_125m_deployment.scale_down_to_n_policy_arn]
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
    }
  ]

  # These variables do not change between LLMs
  source                = "./modules/sagemaker_deployment"
  security_group_ids    = [aws_security_group.notebooks.id]
  subnets               = aws_subnet.private_without_egress.*.id
  s3_output_path        = "https://${module.iam.default_sagemaker_bucket.bucket_regional_domain_name}"
  aws_account_id        = data.aws_caller_identity.aws_caller_identity.account_id
  sns_success_topic_arn = module.sagemaker_output_mover.sns_success_topic_arn
  execution_role_arn    = module.iam.inference_role
}

###############
# Phi 2 3b
###############
module "phi_2_3b_deployment" {
  model_name            = "phi-2-3b"
  container_image       = "763104351884.dkr.ecr.eu-west-2.amazonaws.com/huggingface-pytorch-tgi-inference:2.1.1-tgi1.4.2-gpu-py310-cu121-ubuntu22.04"
  model_uri             = "s3://jumpstart-cache-prod-eu-west-2/huggingface-llm/huggingface-llm-phi-2/artifacts/inference-prepack/v1.0.0/"
  model_uri_compression = "None"
  instance_type         = "ml.g5.xlarge" # 4 vCPU and 1 GPU and 16 GB-RAM
  max_capacity          = 2
  min_capacity          = 0
  scale_up_cooldown     = 0
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
      alarm_name_prefix   = "backlog"  # TODO: backlog is currently required to have index 0, which is brittle
      alarm_description   = "Scale based on existence of backlog or not"
      metric_name         = "ApproximateBacklogSize"
      namespace           = "AWS/SageMaker"
      comparison_operator = "GreaterThanOrEqualToThreshold"
      threshold           = 1
      evaluation_periods  = 1
      datapoints_to_alarm = 1
      period              = 60
      statistic           = "Maximum"
      slack_webhook_url   = var.slack_webhook_backlog_alerts
      alarm_actions       = [module.phi_2_3b_deployment.scale_up_to_one_policy_arn]
      ok_actions          = [module.phi_2_3b_deployment.scale_down_to_zero_policy_arn]
    },
    {
      alarm_name_prefix   = "high-cpu"
      alarm_description   = "Scale up when CPU usage is heavy"
      metric_name         = "CPUUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "GreaterThanOrEqualToThreshold"
      threshold           = 80 * 4  # TODO: we must manually multiply by vCPU count as Normalized metric not available
      evaluation_periods  = 1
      datapoints_to_alarm = 1
      period              = 60
      statistic           = "Maximum"
      slack_webhook_url   = var.slack_webhook_cpu_alerts
      alarm_actions       = [module.phi_2_3b_deployment.scale_up_to_n_policy_arn]
      ok_actions          = []
    },
    {
      alarm_name_prefix   = "low-cpu"
      alarm_description   = "Scale down when CPU usage is light"
      metric_name         = "CPUUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "LessThanOrEqualToThreshold"
      threshold           = 20 * 4  # TODO: we must manually multiply by vCPU count as Normalized metric not available
      evaluation_periods  = 1
      datapoints_to_alarm = 1
      period              = 60
      statistic           = "Maximum"
      slack_webhook_url   = var.slack_webhook_cpu_alerts
      alarm_actions       = [module.phi_2_3b_deployment.scale_down_to_n_policy_arn]
      ok_actions          = []
    },
    {
      alarm_name_prefix   = "high-gpu"
      alarm_description   = "Scale up when GPU usage is heavy"
      metric_name         = "GPUUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "GreaterThanOrEqualToThreshold"
      threshold           = 80 * 1  # TODO: we must manually multiply by GPU count as Normalized metric not available
      evaluation_periods  = 1
      datapoints_to_alarm = 1
      period              = 60
      statistic           = "Maximum"
      slack_webhook_url   = var.slack_webhook_gpu_alerts
      alarm_actions       = [module.phi_2_3b_deployment.scale_up_to_n_policy_arn]
      ok_actions          = []
    },
    {
      alarm_name_prefix   = "low-gpu"
      alarm_description   = "Scale down when GPU usage is light"
      metric_name         = "GPUUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "LessThanOrEqualToThreshold"
      threshold           = 20 * 1  # TODO: we must manually multiply by GPU count as Normalized metric not available
      evaluation_periods  = 1
      datapoints_to_alarm = 1
      period              = 60
      statistic           = "Maximum"
      slack_webhook_url   = var.slack_webhook_gpu_alerts
      alarm_actions       = [module.phi_2_3b_deployment.scale_down_to_n_policy_arn]
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
      alarm_actions       = [module.phi_2_3b_deployment.scale_up_to_n_policy_arn]
      ok_actions          = []
    },
    {
      alarm_name_prefix   = "low-ram"
      alarm_description   = "Scale down when RAM usage is light"
      metric_name         = "MemoryUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "LessThanOrEqualToThreshold"
      threshold           = 20
      evaluation_periods  = 1
      datapoints_to_alarm = 1
      period              = 60
      statistic           = "Maximum"
      slack_webhook_url   = var.slack_webhook_resource_alerts
      alarm_actions       = [module.phi_2_3b_deployment.scale_down_to_n_policy_arn]
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
      alarm_actions       = [module.phi_2_3b_deployment.scale_up_to_n_policy_arn]
      ok_actions          = []
    },
    {
      alarm_name_prefix   = "low-hard-disk"
      alarm_description   = "Scale down when Hard Disk usage is light"
      metric_name         = "DiskUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "LessThanOrEqualToThreshold"
      threshold           = 20
      evaluation_periods  = 1
      datapoints_to_alarm = 1
      period              = 60
      statistic           = "Maximum"
      slack_webhook_url   = var.slack_webhook_resource_alerts
      alarm_actions       = [module.phi_2_3b_deployment.scale_down_to_n_policy_arn]
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
    }
  ]

  # These variables do not change between LLMs
  source                = "./modules/sagemaker_deployment"
  security_group_ids    = [aws_security_group.notebooks.id]
  subnets               = aws_subnet.private_without_egress.*.id
  s3_output_path        = "https://${module.iam.default_sagemaker_bucket.bucket_regional_domain_name}"
  aws_account_id        = data.aws_caller_identity.aws_caller_identity.account_id
  sns_success_topic_arn = module.sagemaker_output_mover.sns_success_topic_arn
  execution_role_arn    = module.iam.inference_role
}


###############
# Mistral 7b
###############
module "mistral_7b_deployment" {
  model_name            = "mistral-7b"
  container_image       = "763104351884.dkr.ecr.eu-west-2.amazonaws.com/huggingface-pytorch-tgi-inference:2.3.0-tgi2.0.3-gpu-py310-cu121-ubuntu22.04"
  model_uri             = "s3://jumpstart-cache-prod-eu-west-2/huggingface-llm/huggingface-llm-mistral-7b-v3/artifacts/inference-prepack/v1.0.0/"
  model_uri_compression = "None"
  instance_type         = "ml.g5.12xlarge" # 48 vCPU and 4 GPU and 192 GB-RAM
  max_capacity          = 2
  min_capacity          = 0
  scale_up_cooldown     = 0
  scale_down_cooldown   = 0
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

  alarms = [
    {
      alarm_name_prefix   = "backlog"  # TODO: backlog is currently required to have index 0, which is brittle
      alarm_description   = "Scale based on existence of backlog or not"
      metric_name         = "ApproximateBacklogSize"
      namespace           = "AWS/SageMaker"
      comparison_operator = "GreaterThanOrEqualToThreshold"
      threshold           = 1
      evaluation_periods  = 1
      datapoints_to_alarm = 1
      period              = 60
      statistic           = "Maximum"
      slack_webhook_url   = var.slack_webhook_backlog_alerts
      alarm_actions       = [module.mistral_7b_deployment.scale_up_to_one_policy_arn]
      ok_actions          = [module.mistral_7b_deployment.scale_down_to_zero_policy_arn]
    },
    {
      alarm_name_prefix   = "high-cpu"
      alarm_description   = "Scale up when CPU usage is heavy"
      metric_name         = "CPUUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "GreaterThanOrEqualToThreshold"
      threshold           = 80 * 48  # TODO: we must manually multiply by vCPU count as Normalized metric not available
      evaluation_periods  = 1
      datapoints_to_alarm = 1
      period              = 60
      statistic           = "Maximum"
      slack_webhook_url   = var.slack_webhook_cpu_alerts
      alarm_actions       = [module.mistral_7b_deployment.scale_up_to_n_policy_arn]
      ok_actions          = []
    },
    {
      alarm_name_prefix   = "low-cpu"
      alarm_description   = "Scale down when CPU usage is light"
      metric_name         = "CPUUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "LessThanOrEqualToThreshold"
      threshold           = 20 * 48  # TODO: we must manually multiply by vCPU count as Normalized metric not available
      evaluation_periods  = 1
      datapoints_to_alarm = 1
      period              = 60
      statistic           = "Maximum"
      slack_webhook_url   = var.slack_webhook_cpu_alerts
      alarm_actions       = [module.mistral_7b_deployment.scale_down_to_n_policy_arn]
      ok_actions          = []
    },
    {
      alarm_name_prefix   = "high-gpu"
      alarm_description   = "Scale up when GPU usage is heavy"
      metric_name         = "GPUUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "GreaterThanOrEqualToThreshold"
      threshold           = 80 * 4  # TODO: we must manually multiply by GPU count as Normalized metric not available
      evaluation_periods  = 1
      datapoints_to_alarm = 1
      period              = 60
      statistic           = "Maximum"
      slack_webhook_url   = var.slack_webhook_gpu_alerts
      alarm_actions       = [module.mistral_7b_deployment.scale_up_to_n_policy_arn]
      ok_actions          = []
    },
    {
      alarm_name_prefix   = "low-gpu"
      alarm_description   = "Scale down when GPU usage is light"
      metric_name         = "GPUUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "LessThanOrEqualToThreshold"
      threshold           = 20 * 4  # TODO: we must manually multiply by GPU count as Normalized metric not available
      evaluation_periods  = 1
      datapoints_to_alarm = 1
      period              = 60
      statistic           = "Maximum"
      slack_webhook_url   = var.slack_webhook_gpu_alerts
      alarm_actions       = [module.mistral_7b_deployment.scale_down_to_n_policy_arn]
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
      alarm_actions       = [module.mistral_7b_deployment.scale_up_to_n_policy_arn]
      ok_actions          = []
    },
    {
      alarm_name_prefix   = "low-ram"
      alarm_description   = "Scale down when RAM usage is light"
      metric_name         = "MemoryUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "LessThanOrEqualToThreshold"
      threshold           = 20
      evaluation_periods  = 1
      datapoints_to_alarm = 1
      period              = 60
      statistic           = "Maximum"
      slack_webhook_url   = var.slack_webhook_resource_alerts
      alarm_actions       = [module.mistral_7b_deployment.scale_down_to_n_policy_arn]
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
      alarm_actions       = [module.mistral_7b_deployment.scale_up_to_n_policy_arn]
      ok_actions          = []
    },
    {
      alarm_name_prefix   = "low-hard-disk"
      alarm_description   = "Scale down when Hard Disk usage is light"
      metric_name         = "DiskUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "LessThanOrEqualToThreshold"
      threshold           = 20
      evaluation_periods  = 1
      datapoints_to_alarm = 1
      period              = 60
      statistic           = "Maximum"
      slack_webhook_url   = var.slack_webhook_resource_alerts
      alarm_actions       = [module.mistral_7b_deployment.scale_down_to_n_policy_arn]
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
    }
  ]

  # These variables do not change between LLMs
  source                = "./modules/sagemaker_deployment"
  security_group_ids    = [aws_security_group.notebooks.id]
  subnets               = aws_subnet.private_without_egress.*.id
  s3_output_path        = "https://${module.iam.default_sagemaker_bucket.bucket_regional_domain_name}"
  aws_account_id        = data.aws_caller_identity.aws_caller_identity.account_id
  sns_success_topic_arn = module.sagemaker_output_mover.sns_success_topic_arn
  execution_role_arn    = module.iam.inference_role
}


###############
# Gemma 2 27b
###############
module "gemma_2_27b_deployment" {
  model_name            = "gemma-2-27b"
  container_image       = "763104351884.dkr.ecr.eu-west-2.amazonaws.com/huggingface-pytorch-tgi-inference:2.4.0-tgi2.3.1-gpu-py311-cu124-ubuntu22.04"
  model_uri             = "s3://jumpstart-private-cache-prod-eu-west-2/huggingface-llm/huggingface-llm-gemma-2-27b/artifacts/inference-prepack/v1.0.0/"
  model_uri_compression = "None"
  instance_type         = "ml.g5.48xlarge" # 192 vCPU and 8 GPU and 768 GB-RAM
  max_capacity          = 2
  min_capacity          = 0
  scale_up_cooldown     = 0
  scale_down_cooldown   = 0
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

  alarms = [
    {
      alarm_name_prefix   = "backlog"  # TODO: backlog is currently required to have index 0, which is brittle
      alarm_description   = "Scale based on existence of backlog or not"
      metric_name         = "ApproximateBacklogSize"
      namespace           = "AWS/SageMaker"
      comparison_operator = "GreaterThanOrEqualToThreshold"
      threshold           = 1
      evaluation_periods  = 1
      datapoints_to_alarm = 1
      period              = 60
      statistic           = "Maximum"
      slack_webhook_url   = var.slack_webhook_backlog_alerts
      alarm_actions       = [module.gemma_2_27b_deployment.scale_up_to_one_policy_arn]
      ok_actions          = [module.gemma_2_27b_deployment.scale_down_to_zero_policy_arn]
    },
    {
      alarm_name_prefix   = "high-cpu"
      alarm_description   = "Scale up when CPU usage is heavy"
      metric_name         = "CPUUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "GreaterThanOrEqualToThreshold"
      threshold           = 80 * 192  # TODO: we must manually multiply by vCPU count as Normalized metric not available
      evaluation_periods  = 1
      datapoints_to_alarm = 1
      period              = 60
      statistic           = "Maximum"
      slack_webhook_url   = var.slack_webhook_cpu_alerts
      alarm_actions       = [module.gemma_2_27b_deployment.scale_up_to_n_policy_arn]
      ok_actions          = []
    },
    {
      alarm_name_prefix   = "low-cpu"
      alarm_description   = "Scale down when CPU usage is light"
      metric_name         = "CPUUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "LessThanOrEqualToThreshold"
      threshold           = 20 * 192  # TODO: we must manually multiply by vCPU count as Normalized metric not available
      evaluation_periods  = 1
      datapoints_to_alarm = 1
      period              = 60
      statistic           = "Maximum"
      slack_webhook_url   = var.slack_webhook_cpu_alerts
      alarm_actions       = [module.gemma_2_27b_deployment.scale_down_to_n_policy_arn]
      ok_actions          = []
    },
    {
      alarm_name_prefix   = "high-gpu"
      alarm_description   = "Scale up when GPU usage is heavy"
      metric_name         = "GPUUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "GreaterThanOrEqualToThreshold"
      threshold           = 80 * 8  # TODO: we must manually multiply by GPU count as Normalized metric not available
      evaluation_periods  = 1
      datapoints_to_alarm = 1
      period              = 60
      statistic           = "Maximum"
      slack_webhook_url   = var.slack_webhook_gpu_alerts
      alarm_actions       = [module.gemma_2_27b_deployment.scale_up_to_n_policy_arn]
      ok_actions          = []
    },
    {
      alarm_name_prefix   = "low-gpu"
      alarm_description   = "Scale down when GPU usage is light"
      metric_name         = "GPUUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "LessThanOrEqualToThreshold"
      threshold           = 20 * 8  # TODO: we must manually multiply by GPU count as Normalized metric not available
      evaluation_periods  = 1
      datapoints_to_alarm = 1
      period              = 60
      statistic           = "Maximum"
      slack_webhook_url   = var.slack_webhook_gpu_alerts
      alarm_actions       = [module.gemma_2_27b_deployment.scale_down_to_n_policy_arn]
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
      alarm_actions       = [module.gemma_2_27b_deployment.scale_up_to_n_policy_arn]
      ok_actions          = []
    },
    {
      alarm_name_prefix   = "low-ram"
      alarm_description   = "Scale down when RAM usage is light"
      metric_name         = "MemoryUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "LessThanOrEqualToThreshold"
      threshold           = 20
      evaluation_periods  = 1
      datapoints_to_alarm = 1
      period              = 60
      statistic           = "Maximum"
      slack_webhook_url   = var.slack_webhook_resource_alerts
      alarm_actions       = [module.gemma_2_27b_deployment.scale_down_to_n_policy_arn]
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
      alarm_actions       = [module.gemma_2_27b_deployment.scale_up_to_n_policy_arn]
      ok_actions          = []
    },
    {
      alarm_name_prefix   = "low-hard-disk"
      alarm_description   = "Scale down when Hard Disk usage is light"
      metric_name         = "DiskUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "LessThanOrEqualToThreshold"
      threshold           = 20
      evaluation_periods  = 1
      datapoints_to_alarm = 1
      period              = 60
      statistic           = "Maximum"
      slack_webhook_url   = var.slack_webhook_resource_alerts
      alarm_actions       = [module.gemma_2_27b_deployment.scale_down_to_n_policy_arn]
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
    }
  ]

  # These variables do not change between LLMs
  source                = "./modules/sagemaker_deployment"
  security_group_ids    = [aws_security_group.notebooks.id]
  subnets               = aws_subnet.private_without_egress.*.id
  s3_output_path        = "https://${module.iam.default_sagemaker_bucket.bucket_regional_domain_name}"
  aws_account_id        = data.aws_caller_identity.aws_caller_identity.account_id
  sns_success_topic_arn = module.sagemaker_output_mover.sns_success_topic_arn
  execution_role_arn    = module.iam.inference_role
}



###############
# Llama 3 70b
###############
module "llama_3_70b_deployment" {
  model_name            = "llama-3-70b"
  container_image       = "763104351884.dkr.ecr.eu-west-2.amazonaws.com/djl-inference:0.31.0-lmi13.0.0-cu124"
  model_uri             = "s3://jumpstart-private-cache-prod-eu-west-2/meta-textgeneration/meta-textgeneration-llama-3-3-70b-instruct/artifacts/inference-prepack/v2.0.0/"
  model_uri_compression = "None"
  instance_type         = "ml.p4d.24xlarge" # 96 vCPU and 8 GPU and 1152 GB-RAM
  max_capacity          = 2
  min_capacity          = 0
  scale_up_cooldown     = 0
  scale_down_cooldown   = 0
  environment_variables = {
    # TODO: This speculative draft feature allows for use of an e.g. 1b parameter model in conjunction with
    # the main 70b model, but to implement it requires hosting the two models together on one instance
    # "OPTION_SPECULATIVE_DRAFT_MODEL": "/opt/ml/additional-model-data-sources/draft_model",
    "ENDPOINT_SERVER_TIMEOUT" : "3600",
    "HF_MODEL_ID" : "/opt/ml/model",
    "MODEL_CACHE_ROOT" : "/opt/ml/model",
    "OPTION_DRAFT_MODEL_TP_SIZE" : "8",
    "OPTION_ENFORCE_EAGER" : "false",
    "OPTION_GPU_MEMORY_UTILIZATION" : "0.95",
    "OPTION_MAX_ROLLING_BATCH_SIZE" : "64",
    "OPTION_TENSOR_PARALLEL_DEGREE" : "8",
    "SAGEMAKER_ENV" : "1",
    "SAGEMAKER_MODEL_SERVER_WORKERS" : "1",
    "SAGEMAKER_PROGRAM" : "inference.py"
  }

  alarms = [
    {
      alarm_name_prefix   = "backlog"  # TODO: backlog is currently required to have index 0, which is brittle
      alarm_description   = "Scale based on existence of backlog or not"
      metric_name         = "ApproximateBacklogSize"
      namespace           = "AWS/SageMaker"
      comparison_operator = "GreaterThanOrEqualToThreshold"
      threshold           = 1
      evaluation_periods  = 1
      datapoints_to_alarm = 1
      period              = 60
      statistic           = "Maximum"
      slack_webhook_url   = var.slack_webhook_backlog_alerts
      alarm_actions       = [module.llama_3_70b_deployment.scale_up_to_one_policy_arn]
      ok_actions          = [module.llama_3_70b_deployment.scale_down_to_zero_policy_arn]
    },
    {
      alarm_name_prefix   = "high-cpu"
      alarm_description   = "Scale up when CPU usage is heavy"
      metric_name         = "CPUUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "GreaterThanOrEqualToThreshold"
      threshold           = 80 * 96
      evaluation_periods  = 1
      datapoints_to_alarm = 1
      period              = 60
      statistic           = "Maximum"
      slack_webhook_url   = var.slack_webhook_cpu_alerts
      alarm_actions       = [module.llama_3_70b_deployment.scale_up_to_n_policy_arn]
      ok_actions          = []
    },
    {
      alarm_name_prefix   = "low-cpu"
      alarm_description   = "Scale down when CPU usage is light"
      metric_name         = "CPUUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "LessThanOrEqualToThreshold"
      threshold           = 20 * 96
      evaluation_periods  = 1
      datapoints_to_alarm = 1
      period              = 60
      statistic           = "Maximum"
      slack_webhook_url   = var.slack_webhook_cpu_alerts
      alarm_actions       = [module.llama_3_70b_deployment.scale_down_to_n_policy_arn]
      ok_actions          = []
    },
    {
      alarm_name_prefix   = "high-gpu"
      alarm_description   = "Scale up when GPU usage is heavy"
      metric_name         = "GPUUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "GreaterThanOrEqualToThreshold"
      threshold           = 80 * 8
      evaluation_periods  = 1
      datapoints_to_alarm = 1
      period              = 60
      statistic           = "Maximum"
      slack_webhook_url   = var.slack_webhook_gpu_alerts
      alarm_actions       = [module.llama_3_70b_deployment.scale_up_to_n_policy_arn]
      ok_actions          = []
    },
    {
      alarm_name_prefix   = "low-gpu"
      alarm_description   = "Scale down when GPU usage is light"
      metric_name         = "GPUUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "LessThanOrEqualToThreshold"
      threshold           = 20 * 8
      evaluation_periods  = 1
      datapoints_to_alarm = 1
      period              = 60
      statistic           = "Maximum"
      slack_webhook_url   = var.slack_webhook_gpu_alerts
      alarm_actions       = [module.llama_3_70b_deployment.scale_down_to_n_policy_arn]
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
      alarm_actions       = [module.llama_3_70b_deployment.scale_up_to_n_policy_arn]
      ok_actions          = []
    },
    {
      alarm_name_prefix   = "low-ram"
      alarm_description   = "Scale down when RAM usage is light"
      metric_name         = "MemoryUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "LessThanOrEqualToThreshold"
      threshold           = 20
      evaluation_periods  = 1
      datapoints_to_alarm = 1
      period              = 60
      statistic           = "Maximum"
      slack_webhook_url   = var.slack_webhook_resource_alerts
      alarm_actions       = [module.llama_3_70b_deployment.scale_down_to_n_policy_arn]
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
      alarm_actions       = [module.llama_3_70b_deployment.scale_up_to_n_policy_arn]
      ok_actions          = []
    },
    {
      alarm_name_prefix   = "low-hard-disk"
      alarm_description   = "Scale down when Hard Disk usage is light"
      metric_name         = "DiskUtilization"
      namespace           = "/aws/sagemaker/Endpoints"
      comparison_operator = "LessThanOrEqualToThreshold"
      threshold           = 20
      evaluation_periods  = 1
      datapoints_to_alarm = 1
      period              = 60
      statistic           = "Maximum"
      slack_webhook_url   = var.slack_webhook_resource_alerts
      alarm_actions       = [module.llama_3_70b_deployment.scale_down_to_n_policy_arn]
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
    }
  ]

  # These variables do not change between LLMs
  source                = "./modules/sagemaker_deployment"
  security_group_ids    = [aws_security_group.notebooks.id]
  subnets               = aws_subnet.private_without_egress.*.id
  s3_output_path        = "https://${module.iam.default_sagemaker_bucket.bucket_regional_domain_name}"
  aws_account_id        = data.aws_caller_identity.aws_caller_identity.account_id
  sns_success_topic_arn = module.sagemaker_output_mover.sns_success_topic_arn
  execution_role_arn    = module.iam.inference_role
}

/*
###############
# Falcon bf16 180b
###############
module "falcon_bf16_180b_deployment" {
  model_name                = "falcon-bf16-180b"
  container_image           = "763104351884.dkr.ecr.eu-west-2.amazonaws.com/huggingface-pytorch-tgi-inference:2.1.1-tgi1.4.0-gpu-py310-cu121-ubuntu20.04"
  model_uri                 = "s3://jumpstart-cache-prod-eu-west-2/huggingface-infer/prepack/v1.2.0/infer-prepack-huggingface-llm-falcon-180b-bf16.tar.gz"
  model_uri_compression     = "Gzip"
  instance_type             = "ml.p5.48xlarge" # 192 vCPU and 8 GPUs and 2048 GB-RAM
  max_capacity              = 2
  min_capacity              = 0
  scale_up_cooldown         = 0
  scale_down_cooldown       = 0
  environment_variables     =  {
    "ENDPOINT_SERVER_TIMEOUT": "3600",
    "HF_MODEL_ID": "/opt/ml/model",
    "MAX_INPUT_LENGTH": "1024",
    "MAX_TOTAL_TOKENS": "2048",
    "MODEL_CACHE_ROOT": "/opt/ml/model",
    "SAGEMAKER_ENV": "1",
    "SAGEMAKER_MODEL_SERVER_WORKERS": "1",
    "SAGEMAKER_PROGRAM": "inference.py",
    "SM_NUM_GPUS": "8"
  }

  alarms = [
    {
      alarm_name_prefix       = "backlog"  # TODO: backlog is currently required to have index 0, which is brittle
      alarm_description       = "Scale based on existence of backlog or not"
      metric_name             = "ApproximateBacklogSize"
      namespace               = "AWS/SageMaker"
      comparison_operator     = "GreaterThanOrEqualToThreshold"
      threshold               = 1
      evaluation_periods      = 1
      datapoints_to_alarm     = 1
      period                  = 60
      statistic               = "Maximum"
      slack_webhook_url       = var.slack_webhook_backlog_alerts
      alarm_actions       = [module.falcon_bf16_180b_deployment.scale_up_from_zero_policy_arn]
      ok_actions          = [module.falcon_bf16_180b_deployment.scale_down_to_zero_policy_arn]
    },
    {
      alarm_name_prefi    = "unauthorized-operations"
      alarm_description   = "Unauthorized operations are detected in the CloudTrail Logs"
      metric_name         = "UnauthorizedOperationsCount"
      namespace           = "CloudTrailMetrics"
      comparison_operator = "GreaterThanThreshold"
      threshold           = 1
      evaluation_periods  = 1
      datapoints_to_alarm = 1
      period              = 60
      statistic           = "Sum"
      slack_webhook_url   = var.slack_webhook_security_alerts
      alarm_actions       = []
      ok_actions          = []
    }
  ]

  # These variables do not change between LLMs
  source                    = "./modules/sagemaker_deployment"
  security_group_ids        = [aws_security_group.notebooks.id]
  subnets                   = aws_subnet.private_without_egress.*.id
  s3_output_path            = "https://${module.iam.default_sagemaker_bucket.bucket_regional_domain_name}"
  aws_account_id            = data.aws_caller_identity.aws_caller_identity.account_id
  sns_success_topic_arn     = module.sagemaker_output_mover.sns_success_topic_arn
  execution_role_arn        = module.iam.inference_role
}
*/
