resource "aws_ecr_repository" "metrics" {
  name = "${var.prefix}-metrics"
}

resource "aws_ecr_lifecycle_policy" "metrics_expire_non_master_non_latest_after_one_day" {
  repository = aws_ecr_repository.metrics.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_non_master_non_latest_after_one_day.json
}
