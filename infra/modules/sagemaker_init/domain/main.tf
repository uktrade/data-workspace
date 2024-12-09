resource "aws_sagemaker_domain" "sagemaker" {
  domain_name = var.domain_name
  auth_mode = "IAM"
  vpc_id = var.vpc_id
  subnet_ids  = var.subnet_ids
  app_network_access_type = "VpcOnly"

  default_user_settings {
    execution_role = var.execution_role_arn
  }
}
