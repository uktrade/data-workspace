
module "sagemaker_domain" {
  source             = "./modules/sagemaker_init/domain"
  domain_name        = "SageMaker"
  vpc_id             = aws_vpc.sagemaker.id
  subnet_ids         = aws_subnet.private_without_egress.*.id
  execution_role_arn = module.iam.execution_role
}

# IAM Roles and Policies for SageMaker
module "iam" {
  source = "./modules/sagemaker_init/iam"
  prefix = "sagemaker"
  sagemaker_default_bucket_name = "${var.sagemaker_default_bucket}"
  aws_s3_bucket_notebook = aws_s3_bucket.notebooks
  account_id = data.aws_caller_identity.aws_caller_identity.account_id
  s3_bucket_arn = module.s3.s3_bucket_arn
  lambda_function_arn = module.lambda_logs.lambda_function_arn

}

module "s3" {
  source ="./modules/s3"
  prefix = "sagemaker-logs"
}


# Security Group for SageMaker Notebooks and Endpoints
# module "security_groups" {
#   source      = "./modules/sagemaker_init/security"
#   vpc_id      = aws_vpc.main.id
#   prefix      = var.prefix
#   cidr_blocks = [aws_vpc.notebooks.cidr_block]
# }

resource "aws_security_group" "notebooks_endpoints" {
  name        = "${var.prefix}-notebooks-endpoints"
  description = "${var.prefix}-notebooks-endpoints"
  vpc_id      = aws_vpc.sagemaker.id

  tags = {
    Name = "${var.prefix}-notebooks-endpoints"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "notebooks_endpoint_ingress_sagemaker" {
  description = "endpoint-ingress-from-datasets-vpc"

  security_group_id        = aws_security_group.notebooks_endpoints.id
  cidr_blocks         = [aws_vpc.notebooks.cidr_block]

  type      = "ingress"
  from_port = "0"
  to_port   = "65535"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "notebooks_endpoint_egress_sagemaker" {
  description = "endpoint-ingress-from-datasets-vpc"

  security_group_id        = aws_security_group.notebooks_endpoints.id
  cidr_blocks         = [aws_vpc.notebooks.cidr_block]

  type      = "egress"
  from_port = "0"
  to_port   = "65535"
  protocol  = "tcp"
}

# SageMaker Execution Role Output
output "execution_role" {
  value       = module.iam.execution_role
  description = "The ARN of the SageMaker execution role"
}


# SageMaker Inference Role Output
output "inference_role" {
  value       = module.iam.inference_role
  description = "The ARN of the SageMaker inference role"
}

# SageMaker Domain Output
output "sagemaker_domain_id" {
  value       = module.sagemaker_domain.sagemaker_domain_id
  description = "The ID of the SageMaker domain"
}

output "default_sagemaker_bucket" {
  value = module.iam.default_sagemaker_bucket
}

# # Security Group Output
# output "security_group_id" {
#   value       = module.security_groups.security_group_id
#   description = "The ID of the security group for SageMaker endpoints"
# }

# Cost monitoring

module "cost_monitoring_dashboard" {
  source      = "./modules/cost_monitoring/sagemaker"
  dashboard_name      = "aws-cost-monitoring-dashboard"
  services_to_monitor       = [
    "AmazonSageMaker",
    "AmazonEC2",
    "AmazonS3"
  ]
}

module "sns" {
  source = "./modules/sns"
  prefix = "data-workspace-sagemaker"
  account_id = data.aws_caller_identity.aws_caller_identity.account_id
  notification_email = var.sagemaker_budget_emails
}

module "log_group" {
  source = "./modules/logs"
  prefix = "data-workspace-sagemaker"
  endpoint_names = local.all_endpoint_names
  lambda_function_arn = module.lambda_logs.lambda_function_arn
}

output "all_subscription_filter_names" {
  value = module.log_group.subscription_filter_names
}

output "all_log_group_arns" {
  value = module.log_group.sagemaker_log_group_arns
}


module "lambda_logs" {
  source = "./modules/lambda"
  s3_bucket_name = "sagemaker-logs-centralized"
  log_delivery_role_arn = module.iam.lambda_execution_role_arn
  sagemaker_log_group_arns = [
    for endpoint_name in local.all_endpoint_names :
    "arn:aws:logs:eu-west-2:${data.aws_caller_identity.aws_caller_identity.account_id}:log-group:/aws/sagemaker/Endpoints/${endpoint_name}:*"
  ]
  account_id = data.aws_caller_identity.aws_caller_identity.account_id
}

module "budgets" {
  source = "./modules/cost_monitoring/budgets"
  budget_limit = "1000"
  cost_filter_service = "Amazon SageMaker"
  budget_name = "sagemaker-budget"
  sns_topic_arn = module.sns.sns_topic_arn
  notification_email = var.sagemaker_budget_emails
}


