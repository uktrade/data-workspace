################
# GPT Neo 125m
###############
module "gpt_neo_125m_deployment" {

  count = (var.sagemaker_on && var.sagemaker_gpt_neo_125m) ? 1 : 0

  model_name            = "gpt-neo-125m"
  container_image       = "763104351884.dkr.ecr.eu-west-2.amazonaws.com/huggingface-pytorch-tgi-inference:2.1.1-tgi1.4.0-gpu-py310-cu121-ubuntu20.04"
  model_uri             = "s3://jumpstart-cache-prod-eu-west-2/huggingface-textgeneration1/huggingface-textgeneration1-gpt-neo-125m/artifacts/inference-prepack/v2.0.0/"
  model_uri_compression = "None"
  instance_type         = "ml.g5.2xlarge" # 8 vCPU and 1 GPU and 32 GB-RAM
  max_capacity          = 2
  scale_up_cooldown     = var.sagemaker_gpt_neo_125m_scale_up_cooldown
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
  backlog_threshold_high   = 1
  backlog_threshold_low    = 1
  cpu_threshold_high       = 80 * 8 # 8 vCPUs
  cpu_threshold_low        = 20 * 8 # 8 vCPUs
  gpu_threshold_high       = 80 * 1 # 1 GPU
  gpu_threshold_low        = 20 * 1 # 1 GPU
  ram_threshold_high       = 80
  ram_threshold_low        = 20
  evaluation_periods_high  = 1
  datapoints_to_alarm_high = 1
  evaluation_periods_low   = 15
  datapoints_to_alarm_low  = 15

  # These variables do not change between LLMs
  source                  = "./modules/sagemaker_deployment"
  security_group_ids      = [aws_security_group.sagemaker[0].id]
  subnets                 = aws_subnet.sagemaker_private_without_egress.*.id
  aws_account_id          = data.aws_caller_identity.aws_caller_identity.account_id
  sns_success_topic_arn   = module.sagemaker_output_mover[0].sns_success_topic_arn
  sns_error_topic_arn     = module.sagemaker_output_mover[0].sns_error_topic_arn
  execution_role_arn      = module.iam[0].inference_role
  teams_webhook_url       = var.teams_webhook_url
  s3_output_path          = module.iam[0].default_sagemaker_bucket_regional_domain_name
  environment_name_prefix = var.prefix
}

################
# Flan T5 780m (Large)
###############
module "flan_t5_780m_deployment" {

  count = (var.sagemaker_on && var.sagemaker_flan_t5_780m) ? 1 : 0

  model_name            = "flan-t5-780m"
  container_image       = "763104351884.dkr.ecr.eu-west-2.amazonaws.com/huggingface-pytorch-tgi-inference:2.1.1-tgi1.4.0-gpu-py310-cu121-ubuntu20.04"
  model_uri             = "s3://jumpstart-cache-prod-eu-west-2/huggingface-text2text/huggingface-text2text-flan-t5-large/artifacts/inference-prepack/v2.0.0/"
  model_uri_compression = "None"
  instance_type         = "ml.g5.2xlarge" # 8 vCPU and 1 GPU and 32 GB-RAM
  max_capacity          = 2
  scale_up_cooldown     = var.sagemaker_flan_t3_780m_scaleup_cooldown
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
  backlog_threshold_high   = 1
  backlog_threshold_low    = 1
  cpu_threshold_high       = 80 * 8 # 8 vCPUs
  cpu_threshold_low        = 20 * 8 # 8 vCPUs
  gpu_threshold_high       = 80 * 1 # 1 GPU
  gpu_threshold_low        = 20 * 1 # 1 GPU
  ram_threshold_high       = 80
  ram_threshold_low        = 20
  evaluation_periods_high  = 1
  datapoints_to_alarm_high = 1
  evaluation_periods_low   = 15
  datapoints_to_alarm_low  = 15

  # These variables do not change between LLMs
  source                  = "./modules/sagemaker_deployment"
  security_group_ids      = [aws_security_group.sagemaker[0].id]
  subnets                 = aws_subnet.sagemaker_private_without_egress.*.id
  aws_account_id          = data.aws_caller_identity.aws_caller_identity.account_id
  sns_success_topic_arn   = module.sagemaker_output_mover[0].sns_success_topic_arn
  sns_error_topic_arn     = module.sagemaker_output_mover[0].sns_error_topic_arn
  execution_role_arn      = module.iam[0].inference_role
  teams_webhook_url       = var.teams_webhook_url
  s3_output_path          = module.iam[0].default_sagemaker_bucket_regional_domain_name
  environment_name_prefix = var.prefix
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
  scale_up_cooldown     = var.sagemaker_phi_2_3b_scaleup_cooldown
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
  backlog_threshold_high   = 1
  backlog_threshold_low    = 1
  cpu_threshold_high       = 80 * 4 # 4 vCPUs
  cpu_threshold_low        = 20 * 4 # 4 vCPUs
  gpu_threshold_high       = 80 * 1 # 1 GPU
  gpu_threshold_low        = 20 * 1 # 1 GPU
  ram_threshold_high       = 80
  ram_threshold_low        = 20
  evaluation_periods_high  = 1
  datapoints_to_alarm_high = 1
  evaluation_periods_low   = 15
  datapoints_to_alarm_low  = 15

  # These variables do not change between LLMs
  source                  = "./modules/sagemaker_deployment"
  security_group_ids      = [aws_security_group.sagemaker[0].id]
  subnets                 = aws_subnet.sagemaker_private_without_egress.*.id
  aws_account_id          = data.aws_caller_identity.aws_caller_identity.account_id
  sns_success_topic_arn   = module.sagemaker_output_mover[0].sns_success_topic_arn
  sns_error_topic_arn     = module.sagemaker_output_mover[0].sns_error_topic_arn
  execution_role_arn      = module.iam[0].inference_role
  teams_webhook_url       = var.teams_webhook_url
  s3_output_path          = module.iam[0].default_sagemaker_bucket_regional_domain_name
  environment_name_prefix = var.prefix
}


###############
# Llama 3.2 3b
###############
module "llama_3_3b_deployment" {

  count = (var.sagemaker_on && var.sagemaker_llama_3_3b) ? 1 : 0

  model_name            = "llama-3-3b"
  container_image       = "763104351884.dkr.ecr.eu-west-2.amazonaws.com/djl-inference:0.31.0-lmi13.0.0-cu124"
  model_uri             = "s3://jumpstart-private-cache-prod-eu-west-2/meta-textgeneration/meta-textgeneration-llama-3-2-3b/artifacts/inference-prepack/v1.0.0/"
  model_uri_compression = "None"
  instance_type         = "ml.g6.xlarge" # 4 vCPU and 1 GPU and 16 GB-RAM
  max_capacity          = 2
  scale_up_cooldown     = var.sagemaker_llama_3_3b_scaleup_cooldown
  scale_down_cooldown   = 0
  environment_variables = {
    "ENDPOINT_SERVER_TIMEOUT" : "3600",
    "HF_MODEL_ID" : "/opt/ml/model",
    "MODEL_CACHE_ROOT" : "/opt/ml/model",
    "OPTION_ENFORCE_EAGER" : "false",
    "OPTION_GPU_MEMORY_UTILIZATION" : "0.95",
    "OPTION_MAX_ROLLING_BATCH_SIZE" : "8",
    "OPTION_TENSOR_PARALLEL_DEGREE" : "1",
    "SAGEMAKER_ENV" : "1",
    "SAGEMAKER_MODEL_SERVER_WORKERS" : "1",
    "SAGEMAKER_PROGRAM" : "inference.py"
  }
  backlog_threshold_high   = 1
  backlog_threshold_low    = 1
  cpu_threshold_high       = 80 * 4 # 4 vCPUs
  cpu_threshold_low        = 20 * 4 # 4 vCPUs
  gpu_threshold_high       = 80 * 1 # 1 GPU
  gpu_threshold_low        = 20 * 1 # 1 GPU
  ram_threshold_high       = 80
  ram_threshold_low        = 20
  evaluation_periods_high  = 1
  datapoints_to_alarm_high = 1
  evaluation_periods_low   = 15 * 4
  datapoints_to_alarm_low  = 15 * 4

  # These variables do not change between LLMs
  source                  = "./modules/sagemaker_deployment"
  security_group_ids      = [aws_security_group.sagemaker[0].id]
  subnets                 = aws_subnet.sagemaker_private_without_egress.*.id
  aws_account_id          = data.aws_caller_identity.aws_caller_identity.account_id
  sns_success_topic_arn   = module.sagemaker_output_mover[0].sns_success_topic_arn
  sns_error_topic_arn     = module.sagemaker_output_mover[0].sns_error_topic_arn
  execution_role_arn      = module.iam[0].inference_role
  teams_webhook_url       = var.teams_webhook_url
  s3_output_path          = module.iam[0].default_sagemaker_bucket_regional_domain_name
  environment_name_prefix = var.prefix
}


###############
# Llama 3.2 3b-instruct
###############
module "llama_3_3b_instruct_deployment" {

  count = (var.sagemaker_on && var.sagemaker_llama_3_3b_instruct) ? 1 : 0

  model_name            = "llama-3-3b-instruct"
  container_image       = "763104351884.dkr.ecr.eu-west-2.amazonaws.com/djl-inference:0.31.0-lmi13.0.0-cu124"
  model_uri             = "s3://jumpstart-private-cache-prod-eu-west-2/meta-textgeneration/meta-textgeneration-llama-3-2-3b-instruct/artifacts/inference-prepack/v1.0.0/"
  model_uri_compression = "None"
  instance_type         = "ml.g6.xlarge" # 4 vCPU and 1 GPU and 16 GB-RAM
  max_capacity          = 2
  scale_up_cooldown     = var.sagemaker_llama_3_3b_instruct_scaleup_cooldown
  scale_down_cooldown   = 0
  environment_variables = {
    "ENDPOINT_SERVER_TIMEOUT" : "3600",
    "HF_MODEL_ID" : "/opt/ml/model",
    "MODEL_CACHE_ROOT" : "/opt/ml/model",
    "OPTION_ENFORCE_EAGER" : "false",
    "OPTION_GPU_MEMORY_UTILIZATION" : "0.95",
    "OPTION_MAX_ROLLING_BATCH_SIZE" : "8",
    "OPTION_TENSOR_PARALLEL_DEGREE" : "1",
    "SAGEMAKER_ENV" : "1",
    "SAGEMAKER_MODEL_SERVER_WORKERS" : "1",
    "SAGEMAKER_PROGRAM" : "inference.py"
  }
  backlog_threshold_high   = 1
  backlog_threshold_low    = 1
  cpu_threshold_high       = 80 * 4 # 4 vCPUs
  cpu_threshold_low        = 20 * 4 # 4 vCPUs
  gpu_threshold_high       = 80 * 1 # 1 GPU
  gpu_threshold_low        = 20 * 1 # 1 GPU
  ram_threshold_high       = 80
  ram_threshold_low        = 20
  evaluation_periods_high  = 1
  datapoints_to_alarm_high = 1
  evaluation_periods_low   = 15 * 4
  datapoints_to_alarm_low  = 15 * 4

  # These variables do not change between LLMs
  source                  = "./modules/sagemaker_deployment"
  security_group_ids      = [aws_security_group.sagemaker[0].id]
  subnets                 = aws_subnet.sagemaker_private_without_egress.*.id
  aws_account_id          = data.aws_caller_identity.aws_caller_identity.account_id
  sns_success_topic_arn   = module.sagemaker_output_mover[0].sns_success_topic_arn
  sns_error_topic_arn     = module.sagemaker_output_mover[0].sns_error_topic_arn
  execution_role_arn      = module.iam[0].inference_role
  teams_webhook_url       = var.teams_webhook_url
  s3_output_path          = module.iam[0].default_sagemaker_bucket_regional_domain_name
  environment_name_prefix = var.prefix
}


###############
# Mistral 7b-instruct
###############
module "mistral_7b_instruct_deployment" {

  count = (var.sagemaker_on && var.sagemaker_mistral_7b_instruct) ? 1 : 0

  model_name            = "mistral-7b-instruct"
  container_image       = "763104351884.dkr.ecr.eu-west-2.amazonaws.com/huggingface-pytorch-tgi-inference:2.3.0-tgi2.0.3-gpu-py310-cu121-ubuntu22.04"
  model_uri             = "s3://jumpstart-cache-prod-eu-west-2/huggingface-llm/huggingface-llm-mistral-7b-instruct-v3/artifacts/inference-prepack/v1.0.0/"
  model_uri_compression = "None"
  instance_type         = "ml.g5.12xlarge" # 48 vCPU and 4 GPU and 192 GB-RAM
  max_capacity          = 2
  scale_up_cooldown     = var.sagemaker_mistral_7b_instruct_scaleup_cooldown
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
    "SAGEMAKER_PROGRAM" : "inference.py",
  }
  backlog_threshold_high   = 1
  backlog_threshold_low    = 1
  cpu_threshold_high       = 80 * 48 # 48 vCPUs
  cpu_threshold_low        = 20 * 48 # 48 vCPUs
  gpu_threshold_high       = 80 * 4  # 4 GPUs
  gpu_threshold_low        = 20 * 4  # 4 GPUs
  ram_threshold_high       = 80
  ram_threshold_low        = 20
  evaluation_periods_high  = 1
  datapoints_to_alarm_high = 1
  evaluation_periods_low   = 15 * 4
  datapoints_to_alarm_low  = 15 * 4

  # These variables do not change between LLMs
  source                  = "./modules/sagemaker_deployment"
  security_group_ids      = [aws_security_group.sagemaker[0].id]
  subnets                 = aws_subnet.sagemaker_private_without_egress.*.id
  aws_account_id          = data.aws_caller_identity.aws_caller_identity.account_id
  sns_success_topic_arn   = module.sagemaker_output_mover[0].sns_success_topic_arn
  sns_error_topic_arn     = module.sagemaker_output_mover[0].sns_error_topic_arn
  execution_role_arn      = module.iam[0].inference_role
  teams_webhook_url       = var.teams_webhook_url
  s3_output_path          = module.iam[0].default_sagemaker_bucket_regional_domain_name
  environment_name_prefix = var.prefix
}

module "sagemaker_outgoing_https" {
  count  = var.sagemaker_on ? 1 : 0
  source = "./modules/security_group_client_server_connections"

  client_security_groups = [aws_security_group.sagemaker[0]]
  server_security_groups = [aws_security_group.sagemaker_endpoints[0]]
  server_prefix_list_ids = [aws_vpc_endpoint.sagemaker_s3[0].prefix_list_id]
  ports                  = [443]
}

resource "aws_security_group" "sagemaker" {
  count = var.sagemaker_on ? 1 : 0

  name        = "${var.prefix}-sagemaker"
  description = "${var.prefix}-sagemaker"
  vpc_id      = aws_vpc.sagemaker[0].id

  tags = {
    Name = "${var.prefix}-sagemaker"
  }

  lifecycle {
    create_before_destroy = true
  }
}