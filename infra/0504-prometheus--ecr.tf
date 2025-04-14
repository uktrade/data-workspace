resource "aws_ecr_repository" "prometheus" {
  name = "${var.prefix}-prometheus"
}

resource "aws_ecr_lifecycle_policy" "prometheus_expire_untagged_after_one_day" {
  repository = aws_ecr_repository.prometheus.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_untagged_after_one_day.json
}
