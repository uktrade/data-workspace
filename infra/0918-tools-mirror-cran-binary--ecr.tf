resource "aws_ecr_repository" "mirrors_sync_cran_binary_rv4" {
  name = "${var.prefix}-mirrors-sync-cran-binary-rv4"
}

resource "aws_ecr_lifecycle_policy" "mirrors_sync_cran_binary_rv4_expire_non_master_non_latest_after_one_day" {
  repository = aws_ecr_repository.mirrors_sync_cran_binary_rv4.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_non_master_non_latest_after_one_day.json
}
