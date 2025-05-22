module "aws_codebuild_project_matchbox" {
  count = var.matchbox_on ? 1 : 0

  source                             = "./modules/codebuild_ecs_deploy"
  name                               = "${var.prefix}-matchbox"
  github_source_url                  = var.matchbox_github_source_url
  dockerfile_path                    = "src/matchbox/server/Dockerfile"
  ecs_service                        = aws_ecs_service.matchbox[count.index]
  ecr_repository                     = aws_ecr_repository.matchbox[0]
  build_on_merge                     = var.matchbox_deploy_on_github_merge
  deploy_on_github_merge_pattern     = var.matchbox_deploy_on_github_merge_pattern
  build_on_release                   = var.matchbox_deploy_on_github_release
  subnets                            = aws_subnet.matchbox_private[*]
  security_group                     = aws_security_group.matchbox_codebuild[count.index]
  region_name                        = data.aws_region.aws_region.name
  account_id                         = data.aws_caller_identity.aws_caller_identity.account_id
  codeconnection_arn                 = var.codeconnection_arn
  cloudwatch_destination_datadog_arn = var.cloudwatch_destination_datadog_arn
}

resource "aws_security_group" "matchbox_codebuild" {
  count = var.matchbox_on ? 1 : 0

  name        = "${var.prefix}-matchbox-codebuild"
  description = "${var.prefix}-matchbox-codebuild"
  vpc_id      = aws_vpc.matchbox[0].id

  tags = {
    Name = "${var.prefix}-matchbox-codebuild"
  }
}

# Allows install of packages via HTTP (Debian) and HTTPS (e.g. Docker Hub / PyPI).
#
# For the avoidance of doubt Debian performs public/private key signature verification on packages,
# where the public key is installed on the base image, which is itself fetched by HTTPS from
# Docker Hub
module "matchbox_codebuild_outgoing_http_https_to_all" {
  count = var.matchbox_on ? 1 : 0

  source                 = "./modules/security_group_client_server_connections"
  client_security_groups = [aws_security_group.matchbox_codebuild[count.index]]
  server_ipv4_cidrs      = ["0.0.0.0/0"]

  ports = [80, 443]
}

module "matchbox_codebuild_outgoing_https_vpc_endpoints" {
  count = var.matchbox_on ? 1 : 0

  source                 = "./modules/security_group_client_server_connections"
  client_security_groups = [aws_security_group.matchbox_codebuild[count.index]]
  server_security_groups = [aws_security_group.matchbox_endpoints[0]]

  ports = [443]
}
