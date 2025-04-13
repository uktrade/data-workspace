resource "aws_ecr_repository" "mlflow" {
  name = "${var.prefix}-mlflow"
}

resource "aws_ecr_lifecycle_policy" "mlflow_expire_untagged_after_one_day" {
  repository = aws_ecr_repository.mlflow.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_untagged_after_one_day.json
}
