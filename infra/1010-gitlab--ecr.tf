resource "aws_ecr_repository" "gitlab" {
  name = "${var.prefix}-gitlab"
}

resource "aws_ecr_lifecycle_policy" "gitlab_expire_untagged_after_one_day" {
  repository = aws_ecr_repository.gitlab.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_tagged_and_untagged.json
}
