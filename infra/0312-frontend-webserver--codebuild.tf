module "aws_codebuild_project_admin" {
  source = "./modules/codebuild_ecs_deploy"

  name              = "${var.prefix}-admin"
  github_source_url = var.admin_github_source_url
  ecs_service       = aws_ecs_service.admin
  ecr_repository    = aws_ecr_repository.admin

  subnets        = aws_subnet.private_with_egress[*]
  security_group = aws_security_group.admin_codebuild

  codeconnection_arn = var.codeconnection_arn

  region_name = data.aws_region.aws_region.name
  account_id  = data.aws_caller_identity.aws_caller_identity.account_id
}

resource "aws_security_group" "admin_codebuild" {
  name        = "${var.prefix}-admin-codebuild"
  description = "${var.prefix}-admin-codebuild"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.prefix}-admin-codebuild"
  }
}

module "admin_codebuild_outgoing_http_to_all" {
  source = "./modules/security_group_client_server_connections"

  client_security_groups = [aws_security_group.admin_codebuild]
  # Allows install of Debian packages which are via HTTP
  server_ipv4_cidrs = [
    "0.0.0.0/0"
  ]
  ports = [80]
}

module "admin_codebuild_outgoing_https_vpc_endpoints" {
  source = "./modules/security_group_client_server_connections"

  client_security_groups = [aws_security_group.admin_codebuild]
  server_security_groups = concat([
    aws_security_group.ecr_api,
    aws_security_group.ecr_dkr,
    aws_security_group.ecs,
    aws_security_group.cloudwatch,
    ]
  )
  server_prefix_list_ids = [
    aws_vpc_endpoint.s3.prefix_list_id
  ]
  # Allows the Docker build to pull in packages from the outside world, e.g. PyPI
  server_ipv4_cidrs = [
    "0.0.0.0/0"
  ]
  ports = [443]
}
