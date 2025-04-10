resource "aws_ecr_repository" "airflow" {
  name = "${var.prefix}-airflow"
}

resource "aws_ecr_lifecycle_policy" "airflow_expire_untagged_after_one_day" {
  repository = aws_ecr_repository.airflow.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_untagged_after_one_day.json
}
