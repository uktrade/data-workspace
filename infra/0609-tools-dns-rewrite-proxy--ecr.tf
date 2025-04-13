resource "aws_ecr_repository" "dns_rewrite_proxy" {
  name = "${var.prefix}-dns-rewrite-proxy"
}

resource "aws_ecr_lifecycle_policy" "dns_rewrite_proxy_expire_untagged_after_one_day" {
  repository = aws_ecr_repository.dns_rewrite_proxy.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_untagged_after_one_day.json
}
