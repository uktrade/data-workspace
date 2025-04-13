resource "aws_ecr_repository" "s3sync" {
  name = "${var.prefix}-s3sync"
}

resource "aws_ecr_lifecycle_policy" "s3sync_expire_non_master_non_latest_after_one_day" {
  repository = aws_ecr_repository.s3sync.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_non_master_non_latest_after_one_day.json
}
