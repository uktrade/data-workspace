// We only ever deploy tagged images, so all ECR repos have a lifecycle policy to delete untagged
// images.
//
// Some repos also expire certain tagged images because they are either kaniko-generated cached
// layers, or no-longer deployed images

resource "aws_ecr_repository" "healthcheck" {
  name = "${var.prefix}-healthcheck"
}

resource "aws_ecr_lifecycle_policy" "healthcheck_expire_untagged_after_one_day" {
  repository = aws_ecr_repository.healthcheck.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_untagged_after_one_day.json
}

resource "aws_ecr_repository" "prometheus" {
  name = "${var.prefix}-prometheus"
}

resource "aws_ecr_lifecycle_policy" "prometheus_expire_untagged_after_one_day" {
  repository = aws_ecr_repository.prometheus.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_untagged_after_one_day.json
}

resource "aws_ecr_repository" "mirrors_sync_cran_binary_rv4" {
  name = "${var.prefix}-mirrors-sync-cran-binary-rv4"
}

resource "aws_ecr_lifecycle_policy" "mirrors_sync_cran_binary_rv4_expire_non_master_non_latest_after_one_day" {
  repository = aws_ecr_repository.mirrors_sync_cran_binary_rv4.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_non_master_non_latest_after_one_day.json
}

resource "aws_ecr_repository" "superset" {
  name = "${var.prefix}-superset"
}

resource "aws_ecr_lifecycle_policy" "superset_expire_untagged_after_one_day" {
  repository = aws_ecr_repository.superset.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_untagged_after_one_day.json
}

resource "aws_ecr_repository" "flower" {
  name = "${var.prefix}-flower"
}

resource "aws_ecr_lifecycle_policy" "flower_expire_untagged_after_one_day" {
  repository = aws_ecr_repository.flower.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_untagged_after_one_day.json
}

resource "aws_ecr_repository" "mlflow" {
  name = "${var.prefix}-mlflow"
}

resource "aws_ecr_lifecycle_policy" "mlflow_expire_untagged_after_one_day" {
  repository = aws_ecr_repository.mlflow.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_untagged_after_one_day.json
}

resource "aws_ecr_repository" "matchbox" {
  count = var.matchbox_on ? 1 : 0
  name  = "${var.prefix}-matchbox"
}
