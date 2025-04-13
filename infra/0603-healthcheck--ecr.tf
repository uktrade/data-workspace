resource "aws_ecr_repository" "healthcheck" {
  name = "${var.prefix}-healthcheck"
}

resource "aws_ecr_lifecycle_policy" "healthcheck_expire_untagged_after_one_day" {
  repository = aws_ecr_repository.healthcheck.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_untagged_after_one_day.json
}
