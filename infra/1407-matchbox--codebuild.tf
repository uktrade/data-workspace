module "aws_codebuild_project_matchbox" {
  count  = var.matchbox_on ? length(var.matchbox_instances) : 0
  source = "./modules/codebuild_ecs_deploy"

  name              = "${var.prefix}-matchbox"
  github_source_url = var.matchbox_github_source_url
  ecs_service       = aws_ecs_service.matchbox[count.index]
  ecr_repository    = aws_ecr_repository.matchbox[count.index]

  subnets        = aws_subnet.matchbox_private[*]
  security_group = aws_security_group.matchbox_codebuild[count.index]

  codeconnection_arn                 = var.codeconnection_arn
  cloudwatch_destination_datadog_arn = var.cloudwatch_destination_datadog_arn

  region_name = data.aws_region.aws_region.name
  account_id  = data.aws_caller_identity.aws_caller_identity.account_id

  build_on_merge                 = true
  build_on_release               = true
  deploy_on_github_merge_pattern = var.matchbox_deploy_on_github_merge_pattern
}

resource "aws_security_group" "matchbox_codebuild" {
  count       = var.matchbox_on ? length(var.matchbox_instances) : 0
  name        = "${var.prefix}-matchbox-codebuild"
  description = "${var.prefix}-matchbox-codebuild"
  vpc_id      = aws_vpc.matchbox[count.index].id

  tags = {
    Name = "${var.prefix}-matchbox-codebuild"
  }
}

module "matchbox_codebuild_outgoing_http_to_all" {
  count  = var.matchbox_on ? length(var.matchbox_instances) : 0
  source = "./modules/security_group_client_server_connections"

  client_security_groups = [aws_security_group.matchbox_codebuild[count.index]]

  # Allows install of Debian packages which are via HTTP
  server_ipv4_cidrs = ["0.0.0.0/0"]

  ports = [80]
}

module "matchbox_codebuild_outgoing_https_vpc_endpoints" {
  count  = var.matchbox_on ? length(var.matchbox_instances) : 0
  source = "./modules/security_group_client_server_connections"

  client_security_groups = [aws_security_group.matchbox_codebuild[count.index]]
  server_security_groups = [aws_security_group.matchbox_endpoints[0]]

  # Allows the Docker build to pull in packages from the outside world, e.g. PyPI
  server_ipv4_cidrs = ["0.0.0.0/0"]

  ports = [443]
}
