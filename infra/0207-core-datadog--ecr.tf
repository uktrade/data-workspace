resource "aws_ecr_repository" "datadog" {
  name = "${var.prefix}-datadog"
}

resource "aws_ecr_lifecycle_policy" "datadog_expire_untagged_after_one_day" {
  repository = aws_ecr_repository.datadog.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_untagged_after_one_day.json
}
