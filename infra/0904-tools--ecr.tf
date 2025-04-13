resource "aws_ecr_repository" "tools" {
  count = length(var.tools)
  name  = "${var.prefix}-${var.tools[count.index].name}"
}

resource "aws_ecr_lifecycle_policy" "tools_expire_untagged_after_one_day" {
  count      = length(var.tools)
  repository = aws_ecr_repository.tools[count.index].name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_untagged_after_one_day.json
}
