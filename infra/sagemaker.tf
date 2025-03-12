module "iam" {
  count = var.sagemaker_on ? 1 : 0

  source                 = "./modules/sagemaker_init/iam"
  prefix                 = var.prefix
  aws_s3_bucket_notebook = aws_s3_bucket.notebooks
  account_id             = data.aws_caller_identity.aws_caller_identity.account_id
  aws_region             = data.aws_region.aws_region.name
}

resource "aws_security_group" "sagemaker_vpc_endpoints_main" {
  count = var.sagemaker_on ? 1 : 0

  name        = "${var.prefix}-sagemaker-vpc-endpoints-main"
  description = "${var.prefix}-sagemaker-vpc-endpoints-main"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.prefix}-sagemaker-vpc-endpoints-main"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "ingress_sagemaker_vpc_endpoint_notebooks_vpc" {
  count = var.sagemaker_on ? 1 : 0

  description = "endpoint-ingress-from-notebooks-vpc"

  security_group_id = aws_security_group.sagemaker_vpc_endpoints_main[0].id
  cidr_blocks       = [aws_vpc.notebooks.cidr_block]

  type      = "ingress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

resource "aws_security_group" "sagemaker_endpoints" {
  count = var.sagemaker_on ? 1 : 0

  name        = "${var.prefix}-sagemaker-endpoints"
  description = "${var.prefix}-sagemaker-endpoints"
  vpc_id      = aws_vpc.sagemaker[0].id

  tags = {
    Name = "${var.prefix}-sagemaker-endpoints"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# SageMaker Execution Role Output
output "execution_role" {

  value       = module.iam[*].execution_role
  description = "The ARN of the SageMaker execution role"
}


# SageMaker Inference Role Output
output "inference_role" {

  value       = module.iam[*].inference_role
  description = "The ARN of the SageMaker inference role"
}

module "cost_monitoring_dashboard" {
  count = var.sagemaker_on ? 1 : 0

  source         = "./modules/cost_monitoring/cloudwatch_dashboard"
  dashboard_name = "aws-cost-monitoring-dashboard"
  services_to_monitor = [
    "AmazonSageMaker",
    "AmazonEC2",
    "AmazonS3"
  ]
}

module "sns" {
  count = var.sagemaker_on ? 1 : 0

  source     = "./modules/cost_monitoring/sns"
  prefix     = var.prefix
  account_id = data.aws_caller_identity.aws_caller_identity.account_id
  #notification_email = var.sagemaker_budget_emails
}

module "sagemaker_output_mover" {
  count = var.sagemaker_on ? 1 : 0

  source                       = "./modules/sagemaker_output_mover"
  account_id                   = data.aws_caller_identity.aws_caller_identity.account_id
  aws_region                   = data.aws_region.aws_region.name
  s3_bucket_notebooks_arn      = aws_s3_bucket.notebooks.arn
  prefix                       = var.prefix
  default_sagemaker_bucket_arn = module.iam[0].default_sagemaker_bucket_arn
}

module "budgets" {
  count = var.sagemaker_on ? 1 : 0

  source              = "./modules/cost_monitoring/budgets"
  budget_limit        = "1000"
  cost_filter_service = "Amazon SageMaker"
  budget_name_prefix  = "${var.prefix}-sagemaker"
  sns_topic_arn       = module.sns[0].sns_topic_arn
  notification_email  = var.sagemaker_budget_emails
}
