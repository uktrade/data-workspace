resource "aws_ecr_repository" "user_provided" {
  name = "${var.prefix}-user-provided"
}

resource "aws_ecr_lifecycle_policy" "user_provided_expire_untagged_after_one_day" {
  repository = aws_ecr_repository.user_provided.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_preview_and_untagged_after_one_day.json
}
