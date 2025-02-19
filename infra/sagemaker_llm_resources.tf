# TODO: better if this is not required to be stated explicitly as it is brittle
locals {
  all_llm_names = [
    module.gpt_neo_125m_deployment.model_name,
    module.flan_t5_780m_deployment.model_name,
    module.phi_2_3b_deployment.model_name,
    module.llama_3_3b_deployment.model_name,
    module.llama_3_3b_instruct_deployment.model_name,
    module.mistral_7b_instruct_deployment.model_name,
    module.llama_3_8b_deployment.model_name,
    module.llama_3_8b_instruct_deployment.model_name
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
  scale_up_cooldown     = 900
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
  source                = "./modules/sagemaker_deployment"
  security_group_ids    = [aws_security_group.sagemaker.id, aws_security_group.sagemaker_endpoints.id]
  subnets               = aws_subnet.sagemaker_private_without_egress.*.id
  s3_output_path        = "https://${module.iam.default_sagemaker_bucket.bucket_regional_domain_name}"
  aws_account_id        = data.aws_caller_identity.aws_caller_identity.account_id
  sns_success_topic_arn = module.sagemaker_output_mover.sns_success_topic_arn
  execution_role_arn    = module.iam.inference_role
}


################
# Flan T5 780m (Large)
###############
module "flan_t5_780m_deployment" {
  model_name            = "flan-t5-780m"
  container_image       = "763104351884.dkr.ecr.eu-west-2.amazonaws.com/huggingface-pytorch-tgi-inference:2.1.1-tgi1.4.0-gpu-py310-cu121-ubuntu20.04"
  model_uri             = "s3://jumpstart-cache-prod-eu-west-2/huggingface-text2text/huggingface-text2text-flan-t5-large/artifacts/inference-prepack/v2.0.0/"
  model_uri_compression = "None"
  instance_type         = "ml.g5.2xlarge" # 8 vCPU and 1 GPU and 32 GB-RAM
  max_capacity          = 2
  min_capacity          = 0
  scale_up_cooldown     = 900
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
  source                = "./modules/sagemaker_deployment"
  security_group_ids    = [aws_security_group.sagemaker.id, aws_security_group.sagemaker_endpoints.id]
  subnets               = aws_subnet.sagemaker_private_without_egress.*.id
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
  source                = "./modules/sagemaker_deployment"
  security_group_ids    = [aws_security_group.sagemaker.id, aws_security_group.sagemaker_endpoints.id]
  subnets               = aws_subnet.sagemaker_private_without_egress.*.id
  s3_output_path        = "https://${module.iam.default_sagemaker_bucket.bucket_regional_domain_name}"
  aws_account_id        = data.aws_caller_identity.aws_caller_identity.account_id
  sns_success_topic_arn = module.sagemaker_output_mover.sns_success_topic_arn
  execution_role_arn    = module.iam.inference_role
}


###############
# Llama 3.2 3b
###############
module "llama_3_3b_deployment" {
  model_name            = "llama-3-3b"
  container_image       = "763104351884.dkr.ecr.eu-west-2.amazonaws.com/djl-inference:0.31.0-lmi13.0.0-cu124"
  model_uri             = "s3://jumpstart-private-cache-prod-eu-west-2/meta-textgeneration/meta-textgeneration-llama-3-2-3b/artifacts/inference-prepack/v1.0.0/"
  model_uri_compression = "None"
  instance_type         = "ml.g6.xlarge" # 4 vCPU and 1 GPU and 16 GB-RAM
  max_capacity          = 2
  min_capacity          = 0
  scale_up_cooldown     = 900 * 4
  scale_down_cooldown   = 0
  environment_variables = {
    "ENDPOINT_SERVER_TIMEOUT" : "3600",
    "HF_MODEL_ID" : "/opt/ml/model",
    "MODEL_CACHE_ROOT" : "/opt/ml/model",
    "OPTION_DRAFT_MODEL_TP_SIZE" : "1",
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
  source                = "./modules/sagemaker_deployment"
  security_group_ids    = [aws_security_group.sagemaker.id, aws_security_group.sagemaker_endpoints.id]
  subnets               = aws_subnet.sagemaker_private_without_egress.*.id
  s3_output_path        = "https://${module.iam.default_sagemaker_bucket.bucket_regional_domain_name}"
  aws_account_id        = data.aws_caller_identity.aws_caller_identity.account_id
  sns_success_topic_arn = module.sagemaker_output_mover.sns_success_topic_arn
  execution_role_arn    = module.iam.inference_role
}


###############
# Llama 3.2 3b-instruct
###############
module "llama_3_3b_instruct_deployment" {
  model_name            = "llama-3-3b-instruct"
  container_image       = "763104351884.dkr.ecr.eu-west-2.amazonaws.com/djl-inference:0.31.0-lmi13.0.0-cu124"
  model_uri             = "s3://jumpstart-private-cache-prod-eu-west-2/meta-textgeneration/meta-textgeneration-llama-3-2-3b-instruct/artifacts/inference-prepack/v1.0.0/"
  model_uri_compression = "None"
  instance_type         = "ml.g6.xlarge" # 4 vCPU and 1 GPU and 16 GB-RAM
  max_capacity          = 2
  min_capacity          = 0
  scale_up_cooldown     = 900 * 4
  scale_down_cooldown   = 0
  environment_variables = {
    "ENDPOINT_SERVER_TIMEOUT" : "3600",
    "HF_MODEL_ID" : "/opt/ml/model",
    "MODEL_CACHE_ROOT" : "/opt/ml/model",
    "OPTION_DRAFT_MODEL_TP_SIZE" : "1",
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
  source                = "./modules/sagemaker_deployment"
  security_group_ids    = [aws_security_group.sagemaker.id, aws_security_group.sagemaker_endpoints.id]
  subnets               = aws_subnet.sagemaker_private_without_egress.*.id
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
  scale_up_cooldown     = 900
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
  evaluation_periods_low   = 15
  datapoints_to_alarm_low  = 15

  # These variables do not change between LLMs
  source                = "./modules/sagemaker_deployment"
  security_group_ids    = [aws_security_group.sagemaker.id, aws_security_group.sagemaker_endpoints.id]
  subnets               = aws_subnet.sagemaker_private_without_egress.*.id
  s3_output_path        = "https://${module.iam.default_sagemaker_bucket.bucket_regional_domain_name}"
  aws_account_id        = data.aws_caller_identity.aws_caller_identity.account_id
  sns_success_topic_arn = module.sagemaker_output_mover.sns_success_topic_arn
  execution_role_arn    = module.iam.inference_role
}


###############
# Mistral 7b-instruct
###############
module "mistral_7b_instruct_deployment" {
  model_name            = "mistral-7b-instruct"
  container_image       = "763104351884.dkr.ecr.eu-west-2.amazonaws.com/huggingface-pytorch-tgi-inference:2.3.0-tgi2.0.3-gpu-py310-cu121-ubuntu22.04"
  model_uri             = "s3://jumpstart-cache-prod-eu-west-2/huggingface-llm/huggingface-llm-mistral-7b-instruct-v3/artifacts/inference-prepack/v1.0.0/"
  model_uri_compression = "None"
  instance_type         = "ml.g5.12xlarge" # 48 vCPU and 4 GPU and 192 GB-RAM
  max_capacity          = 2
  min_capacity          = 0
  scale_up_cooldown     = 900
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
  evaluation_periods_low   = 15
  datapoints_to_alarm_low  = 15

  # These variables do not change between LLMs
  source                = "./modules/sagemaker_deployment"
  security_group_ids    = [aws_security_group.sagemaker.id, aws_security_group.sagemaker_endpoints.id]
  subnets               = aws_subnet.sagemaker_private_without_egress.*.id
  s3_output_path        = "https://${module.iam.default_sagemaker_bucket.bucket_regional_domain_name}"
  aws_account_id        = data.aws_caller_identity.aws_caller_identity.account_id
  sns_success_topic_arn = module.sagemaker_output_mover.sns_success_topic_arn
  execution_role_arn    = module.iam.inference_role
}


###############
# Llama 3.1 8b
###############
module "llama_3_8b_deployment" {
  model_name            = "llama-3-8b"
  container_image       = "763104351884.dkr.ecr.eu-west-2.amazonaws.com/djl-inference:0.31.0-lmi13.0.0-cu124"
  model_uri             = "s3://jumpstart-private-cache-prod-eu-west-2/meta-textgeneration/meta-textgeneration-llama-3-1-8b/artifacts/inference-prepack/v2.0.0/"
  model_uri_compression = "None"
  instance_type         = "ml.g5.4xlarge" # 16 vCPU and 1 GPU and 64 GB-RAM
  max_capacity          = 2
  min_capacity          = 0
  scale_up_cooldown     = 900
  scale_down_cooldown   = 0
  environment_variables = {
    "ENDPOINT_SERVER_TIMEOUT" : "3600",
    "HF_MODEL_ID" : "/opt/ml/model",
    "MODEL_CACHE_ROOT" : "/opt/ml/model",
    "SAGEMAKER_ENV" : "1",
    "SAGEMAKER_MODEL_SERVER_WORKERS" : "1",
    "SAGEMAKER_PROGRAM" : "inference.py",

    "MAX_MODEL_LEN=4096"????
    max_rolling_batch_prefill_tokens???
    cuda-memory-fraction???

    "OPTION_GPU_MEMORY_UTILIZATION": "0.85",
    "OPTION_ENABLE_CHUNKED_PREFILL": "false",
    "OPTION_ENFORCE_EAGER": "false",
    "OPTION_MAX_ROLLING_BATCH_SIZE": "16",
    "OPTION_TENSOR_PARALLEL_DEGREE": "1",

    "PYTORCH_CUDA_ALLOC_CONF": "expandable_segments:True,max_split_size_mb:512",
  }
  backlog_threshold_high   = 1
  backlog_threshold_low    = 1
  cpu_threshold_high       = 80 * 16 # 16 vCPUs
  cpu_threshold_low        = 20 * 16 # 16 vCPUs
  gpu_threshold_high       = 80 * 1  # 1 GPU
  gpu_threshold_low        = 20 * 1  # 1 GPU
  ram_threshold_high       = 80
  ram_threshold_low        = 20
  evaluation_periods_high  = 1
  datapoints_to_alarm_high = 1
  evaluation_periods_low   = 15
  datapoints_to_alarm_low  = 15

  # These variables do not change between LLMs
  source                = "./modules/sagemaker_deployment"
  security_group_ids    = [aws_security_group.sagemaker.id, aws_security_group.sagemaker_endpoints.id]
  subnets               = aws_subnet.sagemaker_private_without_egress.*.id
  s3_output_path        = "https://${module.iam.default_sagemaker_bucket.bucket_regional_domain_name}"
  aws_account_id        = data.aws_caller_identity.aws_caller_identity.account_id
  sns_success_topic_arn = module.sagemaker_output_mover.sns_success_topic_arn
  execution_role_arn    = module.iam.inference_role
}


###############
# Llama 3.1 8b-instruct
###############
module "llama_3_8b_instruct_deployment" {
  model_name            = "llama-3-8b-instruct"
  container_image       = "763104351884.dkr.ecr.eu-west-2.amazonaws.com/djl-inference:0.31.0-lmi13.0.0-cu124"
  model_uri             = "s3://jumpstart-private-cache-prod-eu-west-2/meta-textgeneration/meta-textgeneration-llama-3-1-8b-instruct/artifacts/inference-prepack/v2.0.0/"
  model_uri_compression = "None"
  instance_type         = "ml.g6.8xlarge" # 16 vCPU and 1 GPU and 64 GB-RAM
  max_capacity          = 2
  min_capacity          = 0
  scale_up_cooldown     = 900
  scale_down_cooldown   = 0
  environment_variables = {
    "ENDPOINT_SERVER_TIMEOUT" : "3600",
    "HF_MODEL_ID" : "/opt/ml/model",
    "MODEL_CACHE_ROOT" : "/opt/ml/model",
    "SAGEMAKER_ENV" : "1",
    "SAGEMAKER_MODEL_SERVER_WORKERS" : "1",
    "SAGEMAKER_PROGRAM" : "inference.py",

    "OPTION_GPU_MEMORY_UTILIZATION": "0.85",
    "OPTION_ENABLE_CHUNKED_PREFILL": "false",
    "OPTION_ENFORCE_EAGER": "false",
    "OPTION_MAX_ROLLING_BATCH_SIZE": "16",
    "OPTION_TENSOR_PARALLEL_DEGREE": "1",

    "PYTORCH_CUDA_ALLOC_CONF": "max_split_size_mb:512",

  }

  backlog_threshold_high   = 1
  backlog_threshold_low    = 1
  cpu_threshold_high       = 80 * 16 # 16 vCPUs
  cpu_threshold_low        = 20 * 16 # 16 vCPUs
  gpu_threshold_high       = 80 * 1  # 1 GPU
  gpu_threshold_low        = 20 * 1  # 1 GPU
  ram_threshold_high       = 80
  ram_threshold_low        = 20
  evaluation_periods_high  = 1
  datapoints_to_alarm_high = 1
  evaluation_periods_low   = 15
  datapoints_to_alarm_low  = 15

  # These variables do not change between LLMs
  source                = "./modules/sagemaker_deployment"
  security_group_ids    = [aws_security_group.sagemaker.id, aws_security_group.sagemaker_endpoints.id]
  subnets               = aws_subnet.sagemaker_private_without_egress.*.id
  s3_output_path        = "https://${module.iam.default_sagemaker_bucket.bucket_regional_domain_name}"
  aws_account_id        = data.aws_caller_identity.aws_caller_identity.account_id
  sns_success_topic_arn = module.sagemaker_output_mover.sns_success_topic_arn
  execution_role_arn    = module.iam.inference_role
}



/*
# Attempt 1 ----- FAILED
    "ENDPOINT_SERVER_TIMEOUT" : "3600",
    "HF_MODEL_ID" : "/opt/ml/model",
    "MODEL_CACHE_ROOT" : "/opt/ml/model",
    "SAGEMAKER_ENV" : "1",
    "SAGEMAKER_MODEL_SERVER_WORKERS" : "1",
    "SAGEMAKER_PROGRAM" : "inference.py",

    "OPTION_DRAFT_MODEL_TP_SIZE" : "1",

    "OPTION_ENFORCE_EAGER": "false",
    "OPTION_GPU_MEMORY_UTILIZATION": "0.95",
    "OPTION_MAX_ROLLING_BATCH_SIZE": "16",
    "OPTION_TENSOR_PARALLEL_DEGREE": "1",

    "OPTION_ENABLE_CHUNKED_PREFILL": "true",


Notes:
:ValueError: The model's max seq len (131072) is larger than the maximum number of tokens that can be stored in KV cache (45200). Try increasing `gpu_memory_utilization` or decreasing `max_model_len` when initializing the engine.



# Attempt 2 ----- FAILED
    "ENDPOINT_SERVER_TIMEOUT" : "3600",
    "HF_MODEL_ID" : "/opt/ml/model",
    "MODEL_CACHE_ROOT" : "/opt/ml/model",
    "SAGEMAKER_ENV" : "1",
    "SAGEMAKER_MODEL_SERVER_WORKERS" : "1",
    "SAGEMAKER_PROGRAM" : "inference.py",

    "OPTION_DRAFT_MODEL_TP_SIZE" : "1",

    "OPTION_ENFORCE_EAGER": "false",
    "OPTION_GPU_MEMORY_UTILIZATION": "0.95",
    "OPTION_MAX_ROLLING_BATCH_SIZE": "16",
    "OPTION_TENSOR_PARALLEL_DEGREE": "1",

Notes:
Caused by: ai.djl.engine.EngineException: Failed to initialize model: invoke handler failure
The model's max seq len (131072) is larger than the maximum number of tokens that can be stored in KV cache (45200). Try increasing `gpu_memory_utilization` or decreasing `max_model_len` when initializing the engine.



# Attempt 3 ------ FAILED
    "ENDPOINT_SERVER_TIMEOUT" : "3600",
    "HF_MODEL_ID" : "/opt/ml/model",
    "MODEL_CACHE_ROOT" : "/opt/ml/model",
    "SAGEMAKER_ENV" : "1",
    "SAGEMAKER_MODEL_SERVER_WORKERS" : "1",
    "SAGEMAKER_PROGRAM" : "inference.py",

    "OPTION_ENFORCE_EAGER": "false",
    "OPTION_GPU_MEMORY_UTILIZATION": "0.95",
    "OPTION_MAX_ROLLING_BATCH_SIZE": "16",
    "OPTION_TENSOR_PARALLEL_DEGREE": "1",



  # Attempt 4 -------- FAILED
      "ENDPOINT_SERVER_TIMEOUT" : "3600",
    "HF_MODEL_ID" : "/opt/ml/model",
    "MODEL_CACHE_ROOT" : "/opt/ml/model",
    "SAGEMAKER_ENV" : "1",
    "SAGEMAKER_MODEL_SERVER_WORKERS" : "1",
    "SAGEMAKER_PROGRAM" : "inference.py",

    "OPTION_ENFORCE_EAGER": "false",
    "OPTION_GPU_MEMORY_UTILIZATION": "0.95",
    "OPTION_MAX_ROLLING_BATCH_SIZE": "8",
    "OPTION_TENSOR_PARALLEL_DEGREE": "1",

Notes:
java.util.concurrent.CompletionException: ai.djl.engine.EngineException: Failed to initialize model: invoke handler failure


# Attempt 5   ------- FAILED
    "ENDPOINT_SERVER_TIMEOUT" : "3600",
    "HF_MODEL_ID" : "/opt/ml/model",
    "MODEL_CACHE_ROOT" : "/opt/ml/model",
    "SAGEMAKER_ENV" : "1",
    "SAGEMAKER_MODEL_SERVER_WORKERS" : "1",
    "SAGEMAKER_PROGRAM" : "inference.py",

    "OPTION_ENABLE_CHUNKED_PREFILL": "false",
    "OPTION_ENFORCE_EAGER": "false",
    "OPTION_GPU_MEMORY_UTILIZATION": "0.95",
    "OPTION_MAX_ROLLING_BATCH_SIZE": "16",
    "OPTION_TENSOR_PARALLEL_DEGREE": "1",
and
  container_image       = "763104351884.dkr.ecr.eu-west-2.amazonaws.com/djl-inference:0.30.0-lmi12.0.0-cu124"

Notes:
Caused by: ai.djl.engine.EngineException: java.util.concurrent.ExecutionException: java.io.IOException: Python worker disconnected.

# Attempt 6 ----- deploys successfully but does not work async
    "ENDPOINT_SERVER_TIMEOUT" : "3600",
    "HF_MODEL_ID" : "/opt/ml/model",
    "MODEL_CACHE_ROOT" : "/opt/ml/model",
    "SAGEMAKER_ENV" : "1",
    "SAGEMAKER_MODEL_SERVER_WORKERS" : "1",
    "SAGEMAKER_PROGRAM" : "inference.py",

    "OPTION_ENABLE_CHUNKED_PREFILL": "false",
    "OPTION_ENFORCE_EAGER": "false",
    "OPTION_GPU_MEMORY_UTILIZATION": "0.95",
    "OPTION_MAX_ROLLING_BATCH_SIZE": "16",
    "OPTION_TENSOR_PARALLEL_DEGREE": "1",
and
  container_image       = "763104351884.dkr.ecr.eu-west-2.amazonaws.com/djl-inference:0.29.0-lmi11.0.0-cu124"


# Attempt 7
    "ENDPOINT_SERVER_TIMEOUT" : "3600",
    "HF_MODEL_ID" : "/opt/ml/model",
    "MODEL_CACHE_ROOT" : "/opt/ml/model",
    "SAGEMAKER_ENV" : "1",
    "SAGEMAKER_MODEL_SERVER_WORKERS" : "1",
    "SAGEMAKER_PROGRAM" : "inference.py",

    "OPTION_ENABLE_CHUNKED_PREFILL": "false",
    "OPTION_ENFORCE_EAGER": "false",
    "OPTION_GPU_MEMORY_UTILIZATION": "0.95",
    "OPTION_MAX_ROLLING_BATCH_SIZE": "16",
    "OPTION_TENSOR_PARALLEL_DEGREE": "1",


# Attempt 8
    "ENDPOINT_SERVER_TIMEOUT" : "3600",
    "HF_MODEL_ID" : "/opt/ml/model",
    "MODEL_CACHE_ROOT" : "/opt/ml/model",
    "SAGEMAKER_ENV" : "1",
    "SAGEMAKER_MODEL_SERVER_WORKERS" : "1",
    "SAGEMAKER_PROGRAM" : "inference.py",

    "OPTION_ENABLE_CHUNKED_PREFILL": "false",
    "OPTION_ENFORCE_EAGER": "true",
    "OPTION_GPU_MEMORY_UTILIZATION": "0.95",
    "OPTION_MAX_ROLLING_BATCH_SIZE": "16",
    "OPTION_TENSOR_PARALLEL_DEGREE": "1",

Notes:
PyProcess - W-144-model-stdout: [1,0]<stdout>:torch.OutOfMemoryError: Error in model execution (input dumped to /tmp/err_execute_model_input_20250218-175501.pkl): CUDA out of memory. Tried to allocate 7.00 GiB. GPU 0 has a total capacity of 21.99 GiB of which 4.48 GiB is free. Process 9916 has 17.50 GiB memory in use. Of the allocated memory 17.00 GiB is allocated by PyTorch, and 8.36 MiB is reserved by PyTorch but unallocated. If reserved but unallocated memory is large try setting PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True to avoid fragmentation. See documentation for Memory Management (https://pytorch.org/docs/stable/notes/cuda.html#environment-variables)


then try
ml.g6.8xlarge  32 CPU, 1 GPU, 128 GB

[INFO ] PyProcess - W-160-model-stdout: [1,0]<stdout>:torch.OutOfMemoryError: Error in model execution (input dumped to /tmp/err_execute_model_input_20250218-192839.pkl): CUDA out of memory. Tried to allocate 7.00 GiB. GPU 0 has a total capacity of 21.96 GiB of which 4.53 GiB is free. Process 28250 has 17.43 GiB memory in use. Of the allocated memory 17.00 GiB is allocated by PyTorch, and 8.36 MiB is reserved by PyTorch but unallocated. If reserved but unallocated memory is large try setting PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True to avoid fragmentation. See documentation for Memory Management (https://pytorch.org/docs/stable/notes/cuda.html#environment-variables)


ml.g6.4xlarge  16 CPU, 1 GPU, 64 GB

[INFO ] PyProcess - W-142-model-stdout: [1,0]<stdout>:torch.OutOfMemoryError: Error in model execution (input dumped to /tmp/err_execute_model_input_20250218-192613.pkl): CUDA out of memory. Tried to allocate 7.00 GiB. GPU 0 has a total capacity of 21.96 GiB of which 4.53 GiB is free. Process 13100 has 17.43 GiB memory in use. Of the allocated memory 17.00 GiB is allocated by PyTorch, and 8.36 MiB is reserved by PyTorch but unallocated. If reserved but unallocated memory is large try setting PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True to avoid fragmentation. See documentation for Memory Management (https://pytorch.org/docs/stable/notes/cuda.html#environment-variables)

(all prior were ml.g5.4xlarge)  16 vCPU and 1 GPU and 64 GB-RAM


*/
