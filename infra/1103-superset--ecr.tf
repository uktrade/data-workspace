resource "aws_ecr_repository" "superset" {
  name = "${var.prefix}-superset"
}

resource "aws_ecr_lifecycle_policy" "superset_expire_untagged_after_one_day" {
  repository = aws_ecr_repository.superset.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_untagged_after_one_day.json
}
