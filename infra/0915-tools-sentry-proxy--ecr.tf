resource "aws_ecr_repository" "sentryproxy" {
  name = "${var.prefix}-sentryproxy"
}

resource "aws_ecr_lifecycle_policy" "sentryproxy_expire_untagged_after_one_day" {
  repository = aws_ecr_repository.sentryproxy.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_untagged_after_one_day.json
}
