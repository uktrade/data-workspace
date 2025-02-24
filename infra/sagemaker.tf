
module "sagemaker_domain" {

  count = var.sagemaker_on ? 1 : 0

  source             = "./modules/sagemaker_init/domain"
  domain_name        = "SageMaker"
  vpc_id             = aws_vpc.notebooks.id
  subnet_ids         = aws_subnet.private_without_egress.*.id
  execution_role_arn = module.iam[0].execution_role
}

# IAM Roles and Policies for SageMaker
module "iam" {

  count = var.sagemaker_on ? 1 : 0

  source                        = "./modules/sagemaker_init/iam"
  prefix                        = var.prefix
  sagemaker_default_bucket_name = var.sagemaker_default_bucket
  aws_s3_bucket_notebook        = aws_s3_bucket.notebooks
  account_id                    = data.aws_caller_identity.aws_caller_identity.account_id

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
  from_port = "0"
  to_port   = "65535"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "egress_sagemaker_vpc_endpoint_notebooks_vpc" {

  count = var.sagemaker_on ? 1 : 0

  description = "endpoint-ingress-from-notebooks-vpc"

  security_group_id = aws_security_group.sagemaker_vpc_endpoints_main[0].id
  cidr_blocks       = [aws_vpc.notebooks.cidr_block]

  type      = "egress"
  from_port = "0"
  to_port   = "65535"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "ingress_sagemaker_vpc_endpoint_sagemaker_vpc" {

  count = var.sagemaker_on ? 1 : 0

  description = "endpoint-ingress-from-sagemaker-vpc"

  security_group_id = aws_security_group.sagemaker_vpc_endpoints_main[0].id
  cidr_blocks       = [aws_vpc.sagemaker[0].cidr_block]

  type      = "ingress"
  from_port = "0"
  to_port   = "65535"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "egress_sagemaker_vpc_endpoints_sagemaker_vpc" {

  count = var.sagemaker_on ? 1 : 0

  description = "endpoint-ingress-from-sagemaker-vpc"

  security_group_id = aws_security_group.sagemaker_vpc_endpoints_main[0].id
  cidr_blocks       = [aws_vpc.sagemaker[0].cidr_block]

  type      = "egress"
  from_port = "0"
  to_port   = "65535"
  protocol  = "tcp"
}

###############################
## To test new SageMaker VPC ##
###############################

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

resource "aws_security_group_rule" "notebooks_endpoint_ingress_sagemaker_test" {

  count = var.sagemaker_on ? 1 : 0

  description = "endpoint-ingress-sagemaker-to-notebooks-vpc"

  security_group_id = aws_security_group.sagemaker_endpoints[0].id
  cidr_blocks       = [aws_vpc.notebooks.cidr_block]

  type      = "ingress"
  from_port = "0"
  to_port   = "65535"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "notebooks_endpoint_egress_sagemaker_test" {

  count = var.sagemaker_on ? 1 : 0

  description = "endpoint-egress-notebooks-to-sagemaker-vpc"

  security_group_id = aws_security_group.sagemaker_endpoints[0].id
  cidr_blocks       = [aws_vpc.notebooks.cidr_block]

  type      = "egress"
  from_port = "0"
  to_port   = "65535"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "sagemaker_vpc_endpoint_egress" {

  count = var.sagemaker_on ? 1 : 0

  description = "endpoint-egress-notebooks-to-sagemaker-vpc"

  security_group_id = aws_security_group.sagemaker_endpoints[0].id
  cidr_blocks       = ["0.0.0.0/0"]

  type      = "egress"
  from_port = "0"
  to_port   = "65535"
  protocol  = "tcp"
}



resource "aws_security_group" "main_to_sagemaker" {

  count = var.sagemaker_on ? 1 : 0

  name        = "${var.prefix}-main-to-sagemaker-endpoints"
  description = "${var.prefix}sagemaker-access-VPC-endpoints-in-main"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.prefix}-sagemaker-endpoints-main"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "sagemaker_to_main_ingress" {

  count = var.sagemaker_on ? 1 : 0

  description = "endpoint-ingress-sagemaker-to-main-vpc"

  security_group_id = aws_security_group.main_to_sagemaker[0].id
  cidr_blocks       = [aws_vpc.sagemaker[0].cidr_block]

  type      = "ingress"
  from_port = "0"
  to_port   = "65535"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "sagemaker_to_main_egress" {

  count = var.sagemaker_on ? 1 : 0

  description = "endpoint-egress-sagemaker-to-main-vpc"

  security_group_id = aws_security_group.main_to_sagemaker[0].id
  cidr_blocks       = [aws_vpc.sagemaker[0].cidr_block]

  type      = "egress"
  from_port = "0"
  to_port   = "65535"
  protocol  = "tcp"
}


#### Used to allow access to VPC endpoints in Main

resource "aws_security_group_rule" "main_ingress_sagemaker_endpoints" {

  count = var.sagemaker_on ? 1 : 0

  description = "endpoint-ingress-sagemaker-to-main-vpc"

  security_group_id = aws_security_group.sagemaker_endpoints[0].id
  cidr_blocks       = [aws_vpc.main.cidr_block]

  type      = "ingress"
  from_port = "0"
  to_port   = "65535"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "sagemaker_endpoints_egress_main" {

  count = var.sagemaker_on ? 1 : 0

  description = "endpoint-egress-notebooks-to-main-vpc"

  security_group_id = aws_security_group.sagemaker_endpoints[0].id
  cidr_blocks       = [aws_vpc.main.cidr_block]

  type      = "egress"
  from_port = "0"
  to_port   = "65535"
  protocol  = "tcp"
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

# SageMaker Domain Output
output "sagemaker_domain_id" {
  value       = module.sagemaker_domain[*].sagemaker_domain_id
  description = "The ID of the SageMaker domain"
}

output "default_sagemaker_bucket" {
  value = module.iam[*].default_sagemaker_bucket
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
  prefix     = "data-workspace-sagemaker"
  account_id = data.aws_caller_identity.aws_caller_identity.account_id
  #notification_email = var.sagemaker_budget_emails
}

module "sagemaker_output_mover" {

  count = var.sagemaker_on ? 1 : 0

  source                  = "./modules/sagemaker_output_mover"
  account_id              = data.aws_caller_identity.aws_caller_identity.account_id
  aws_region              = data.aws_region.aws_region.name
  s3_bucket_notebooks_arn = aws_s3_bucket.notebooks.arn
}

module "log_group" {

  count = var.sagemaker_on ? 1 : 0

  source              = "./modules/cloudwatch_logs/sagemaker"
  prefix              = "data-workspace-sagemaker"
  endpoint_names      = [for model_name in local.all_llm_names : "${model_name}-endpoint"]
}

output "all_log_group_arns" {
  value = module.log_group[*].sagemaker_log_group_arns
}


module "budgets" {

  count = var.sagemaker_on ? 1 : 0

  source              = "./modules/cost_monitoring/budgets"
  budget_limit        = "1000"
  cost_filter_service = "Amazon SageMaker"
  budget_name         = "sagemaker-budget"
  sns_topic_arn       = module.sns[0].sns_topic_arn
  notification_email  = var.sagemaker_budget_emails
}
