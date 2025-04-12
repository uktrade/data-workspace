resource "aws_ecr_repository" "arango" {
  count = var.arango_on ? 1 : 0
  name  = "${var.prefix}-arango"
}

resource "aws_ecr_lifecycle_policy" "arango_expire_untagged_after_one_day" {
  count      = var.arango_on ? 1 : 0
  repository = aws_ecr_repository.arango[0].name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_untagged_after_one_day.json
}
