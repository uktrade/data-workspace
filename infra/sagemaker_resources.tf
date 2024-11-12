# Instantiate SageMaker Model for GPT-Neo-125
module "gpt_neo_125_model" {
  source             = "./modules/sagemaker_model"  # Use correct relative path for infra/modules
  model_name         = "gpt-neo-125m"
  execution_role_arn = module.iam.inference_role
  container_image    = "${var.hugging_face_model_image}"
  model_data_url     = "${var.sagemaker_models_folder}/gpt-neo-125m.tar.gz"
  environment        = {
    "HF_MODEL_ID"      = "/opt/ml/model/"
    "SM_NUM_GPUS"      = 1
    "MAX_INPUT_LENGTH" = 1024
    "MAX_TOTAL_TOKENS" = 2048
  }
  security_group_ids = ["${aws_security_group.notebooks.id}"]
  subnets            = aws_subnet.private_without_egress.*.id
}

# Instantiate SageMaker Endpoint for GPT-Neo-125 with Custom Variant
module "gpt_neo_125_endpoint" {
  source                                = "./modules/sagemaker_endpoint"  # Correct relative path for infra/modules
  endpoint_name                         = "gpt-neo-125-endpoint"
  endpoint_config_name                  = "sagemaker-endpoint-config-gpt-neo-125m"
  variant_name                          = "gpt-neo-125m-endpoint-example"
  model_name                            = module.gpt_neo_125_model.model_name
  instance_type                         = "ml.g5.2xlarge"
  initial_instance_count                = 1
  container_startup_health_check_timeout_in_seconds = 90
  async_output_s3_path                  = "https://${module.iam.default_sagemaker_bucket.bucket_regional_domain_name}"
}

# Instantiate Autoscaling for the SageMaker Endpoint
module "gpt_neo_125_autoscaling" {
  source                = "./modules/autoscaling/sagemaker"  # Correct relative path for infra/modules
  resource_id           = "endpoint/${module.gpt_neo_125_endpoint.endpoint_name}/variant/${module.gpt_neo_125_endpoint.variant_name}"
  scalable_dimension    = "sagemaker:variant:DesiredInstanceCount"
  min_capacity          = 0
  max_capacity          = 2
  scale_in_cooldown     = 60
  scale_out_cooldown    = 60
  scale_in_to_zero_cooldown = 120
}

# CloudWatch Alarm for Scaling Up (Triggered by Backlog)
module "gpt_neo_125_scale_up_alarm" {
  source              = "./modules/cloudwatch_alarm/sagemaker"  # Correct relative path for infra/modules
  alarm_name          = "backlog-alarm-${module.gpt_neo_125_endpoint.endpoint_name}"
  alarm_description   = "Scale up to 1 when queries are in the backlog, if 0 instances"
  metric_name         = "HasBacklogWithoutCapacity"
  namespace           = "AWS/SageMaker"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  endpoint_name = module.gpt_neo_125_endpoint.endpoint_name
  variant_name = null
  threshold           = 1 # Trigger alarm if the backlog metric is greater or equal to 1
  evaluation_periods  = 1 # Number of periods to evaluate before triggering the alarm
  datapoints_to_alarm = 1   # Data points that must be breaching to trigger alarm
  period              = 60
  alarm_actions       = [module.gpt_neo_125_autoscaling.scale_up_policy_arn]
}

# CloudWatch Alarm for Scaling In to Zero (Triggered by Low CPU Utilization)
module "gpt_neo_125_scale_in_to_zero_alarm" {
  source              = "./modules/cloudwatch_alarm/sagemaker"  # Correct relative path for infra/modules
  alarm_name          = "low-cpu-alarm-${module.gpt_neo_125_endpoint.endpoint_name}"
  alarm_description   = "Scale in to zero when CPU <  5%"
  metric_name         = "CPUUtilization"
  namespace           = "/aws/sagemaker/Endpoints"
  comparison_operator = "LessThanThreshold"
  endpoint_name = module.gpt_neo_125_endpoint.endpoint_name
  variant_name = module.gpt_neo_125_endpoint.variant_name
  datapoints_to_alarm = 1
  threshold           = 5.0
  evaluation_periods  = 3
  period              = 360
  alarm_actions       = [module.gpt_neo_125_autoscaling.scale_in_to_zero_policy_arn]
}

# CloudWatch Alarm for Scale Out (Triggered by High CPU Utilization)
module "gpt_neo_125_scale_out_cpu_alarm" {
  source              = "./modules/cloudwatch_alarm/sagemaker"  # Correct relative path for infra/modules
  alarm_name          = "high-cpu-alarm-${module.gpt_neo_125_endpoint.endpoint_name}"
  alarm_description   = "Scale out when CPU is at 70% threshold"
  metric_name         = "CPUUtilization"
  namespace           = "/aws/sagemaker/Endpoints"
  comparison_operator = "GreaterThanThreshold"
  endpoint_name = module.gpt_neo_125_endpoint.endpoint_name
  variant_name = module.gpt_neo_125_endpoint.variant_name
  datapoints_to_alarm = 1
  threshold           = 70
  evaluation_periods  = 2
  period              = 360
  alarm_actions       = [module.gpt_neo_125_autoscaling.scale_out_cpu_policy_arn]
}

# Instantiate SageMaker Model for Llama-3.2-1B
module "llama_3_2_1b" {
  source             = "./modules/sagemaker_model"  # Use correct relative path for infra/modules
  model_name         = "Llama-3-2-1B"
  execution_role_arn = module.iam.inference_role
  container_image    = "${var.hugging_face_model_image}"
  model_data_url     = "${var.sagemaker_models_folder}/Llama-3.2-1B.tar.gz"
  environment        = {
    "HF_MODEL_ID"      = "/opt/ml/model/"
    "SM_NUM_GPUS"      = 1
    "MAX_INPUT_LENGTH" = 1024
    "MAX_TOTAL_TOKENS" = 2048
  }
  security_group_ids = ["${aws_security_group.notebooks.id}"]
  subnets            = aws_subnet.private_without_egress.*.id
}

# Instantiate SageMaker Endpoint for GPT-Neo-125 with Custom Variant
module "llama_3_2_1b_endpoint" {
  source                                = "./modules/sagemaker_endpoint"  # Correct relative path for infra/modules
  endpoint_name                         = "llama-3-2-1b-endpoint"
  endpoint_config_name                  = "sagemaker-endpoint-config-llama-3-2-1B"
  variant_name                          = "llama-3-2-1B-endpoint-example-1"
  model_name                            = module.llama_3_2_1b.model_name
  instance_type                         = "ml.g5.2xlarge"
  initial_instance_count                = 1
  container_startup_health_check_timeout_in_seconds = 90
  async_output_s3_path                  = "https://${module.iam.default_sagemaker_bucket.bucket_regional_domain_name}"
}

# Instantiate Autoscaling for the SageMaker Endpoint
module "llama_3_2_1b_autoscaling" {
  source                = "./modules/autoscaling/sagemaker"  # Correct relative path for infra/modules
  resource_id           = "endpoint/${module.llama_3_2_1b_endpoint.endpoint_name}/variant/${module.llama_3_2_1b_endpoint.variant_name}"
  scalable_dimension    = "sagemaker:variant:DesiredInstanceCount"
  min_capacity          = 0
  max_capacity          = 2
  scale_in_cooldown     = 60
  scale_out_cooldown    = 60
  scale_in_to_zero_cooldown = 120
}

# CloudWatch Alarm for Scaling Up (Triggered by Backlog)
module "llama_3_2_1b_scale_up_alarm" {
  source              = "./modules/cloudwatch_alarm/sagemaker"  # Correct relative path for infra/modules
  alarm_name          = "backlog-alarm-${module.llama_3_2_1b_endpoint.endpoint_name}"
  alarm_description   = "Scale up to 1 when queries are in the backlog, if 0 instances"
  metric_name         = "HasBacklogWithoutCapacity"
  namespace           = "AWS/SageMaker"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  endpoint_name = module.llama_3_2_1b_endpoint.endpoint_name
  variant_name = null
  threshold           = 1 # Trigger alarm if the backlog metric is greater or equal to 1
  evaluation_periods  = 1 # Number of periods to evaluate before triggering the alarm
  datapoints_to_alarm = 1   # Data points that must be breaching to trigger alarm
  period              = 60
  alarm_actions       = [module.llama_3_2_1b_autoscaling.scale_up_policy_arn]
}

# CloudWatch Alarm for Scaling In to Zero (Triggered by Low CPU Utilization)
module "llama_3_2_1b_scale_in_to_zero_alarm" {
  source              = "./modules/cloudwatch_alarm/sagemaker"  # Correct relative path for infra/modules
  alarm_name          = "low-cpu-alarm-${module.llama_3_2_1b_endpoint.endpoint_name}"
  alarm_description   = "Scale in to zero when CPU <  5%"
  metric_name         = "CPUUtilization"
  namespace           = "/aws/sagemaker/Endpoints"
  comparison_operator = "LessThanThreshold"
  endpoint_name = module.llama_3_2_1b_endpoint.endpoint_name
  variant_name = module.llama_3_2_1b_endpoint.variant_name
  datapoints_to_alarm = 1
  threshold           = 5.0
  evaluation_periods  = 3
  period              = 360
  alarm_actions       = [module.llama_3_2_1b_autoscaling.scale_in_to_zero_policy_arn]
}

# CloudWatch Alarm for Scale Out (Triggered by High CPU Utilization)
module "llama_3_2_1b_scale_out_cpu_alarm" {
  source              = "./modules/cloudwatch_alarm/sagemaker"  # Correct relative path for infra/modules
  alarm_name          = "high-cpu-alarm-${module.llama_3_2_1b_endpoint.endpoint_name}"
  alarm_description   = "Scale out when CPU is at 70% threshold"
  metric_name         = "CPUUtilization"
  namespace           = "/aws/sagemaker/Endpoints"
  comparison_operator = "GreaterThanThreshold"
  endpoint_name = module.llama_3_2_1b_endpoint.endpoint_name
  variant_name = module.llama_3_2_1b_endpoint.variant_name
  datapoints_to_alarm = 1
  threshold           = 70
  evaluation_periods  = 2
  period              = 360
  alarm_actions       = [module.llama_3_2_1b_autoscaling.scale_out_cpu_policy_arn]
}