resource "aws_ecr_repository" "gitlab" {
  name = "${var.prefix}-gitlab"
}

resource "aws_ecr_lifecycle_policy" "gitlab_expire_untagged_after_one_day" {
  repository = aws_ecr_repository.gitlab.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_untagged_after_one_day.json
}

module "gitlab_outgoing_https_ecr_api" {
  count  = var.gitlab_on ? 1 : 0
  source = "./modules/security_group_client_server_connections"

  client_security_groups = [aws_security_group.gitlab_service[count.index]]
  server_security_groups = [aws_security_group.ecr_api]
  ports                  = [443]
}