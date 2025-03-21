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

  security_group_id        = aws_security_group.sagemaker_vpc_endpoints_main[0].id
  source_security_group_id = aws_security_group.notebooks.id

  type      = "ingress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"

  depends_on = [
    # Security groups rules referencing security groups in different VPCs need the peering
    # connection setup first, and although oddly named, this connection links the notebooks and
    # main VPCs
    aws_vpc_peering_connection.jupyterhub
  ]
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


module "budgets" {
  count = var.sagemaker_on ? 1 : 0

  source              = "./modules/cost_monitoring/budgets"
  budget_limit        = "1000"
  cost_filter_service = "Amazon SageMaker"
  budget_name_prefix  = "${var.prefix}-sagemaker"
  sns_topic_arn       = module.sns[0].sns_topic_arn
  notification_email  = var.sagemaker_budget_emails
}


module "sagemaker_output_mover" {
  count = var.sagemaker_on ? 1 : 0

  source                          = "./modules/sagemaker_output_mover"
  account_id                      = data.aws_caller_identity.aws_caller_identity.account_id
  aws_region                      = data.aws_region.aws_region.name
  s3_bucket_notebooks_arn         = aws_s3_bucket.notebooks.arn
  prefix                          = var.prefix
  default_sagemaker_bucket_arn    = module.iam[0].default_sagemaker_bucket_arn
  lambda_layer_boto3_stubs_s3_arn = module.lambda_layers.lambda_layer_boto3_stubs_s3_arn
}


module "store_sagemaker_invokes" {
  source                          = "./modules/store_sagemaker_invokes"
  prefix                          = var.prefix
  aws_region                      = data.aws_region.aws_region.name
  account_id                      = data.aws_caller_identity.aws_caller_identity.account_id
  sns_success_topic_arn           = module.sagemaker_output_mover[0].sns_success_topic_arn
  sns_error_topic_arn             = module.sagemaker_output_mover[0].sns_error_topic_arn
  vpc_id_datasets                 = aws_vpc.datasets.id
  datasets_security_group_id      = aws_security_group.datasets.id
  datasets_route_table_id         = aws_route_table.datasets.id
  datasets_subnet_ids             = aws_subnet.datasets.*.id
  notebooks_s3_bucket_arn         = aws_s3_bucket.notebooks.arn
  datasets_db_username            = aws_rds_cluster.datasets.master_username
  datasets_db_password            = random_password.datasets_db.result
  datasets_db_host                = aws_rds_cluster.datasets.endpoint
  datasets_db_arn                 = aws_rds_cluster.datasets.arn
  datasets_db_secret_arn          = aws_secretsmanager_secret_version.datasets_db.arn
  datasets_db_port                = aws_rds_cluster.datasets.port
  datasets_db_name                = aws_rds_cluster.datasets.database_name
  lambda_layer_pyscopg3_arn       = module.lambda_layers.lambda_layer_pyscopg3_arn
}


module "lambda_layers" {
  source                        = "./modules/lambda_layers"
  prefix                        = var.prefix
  aws_region                    = data.aws_region.aws_region.name
}
