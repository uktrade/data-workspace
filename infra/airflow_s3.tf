resource "aws_s3_bucket" "airflow" {
  count  = var.airflow_on ? length(var.airflow_dag_processors) : 0
  bucket = "${var.prefix}-${var.airflow_bucket_infix}-${replace(var.airflow_dag_processors[count.index].name, "_", "-")}"


  server_side_encryption_configuration {
    rule {
      bucket_key_enabled = false
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  versioning {
    enabled = true
  }

  lifecycle_rule {
    enabled = true

    noncurrent_version_expiration {
      days = 365
    }
    abort_incomplete_multipart_upload_days = 7
  }
}

resource "aws_s3_bucket_policy" "airflow" {
  count  = var.airflow_on ? length(var.airflow_dag_processors) : 0
  bucket = aws_s3_bucket.airflow[count.index].id
  policy = data.aws_iam_policy_document.airflow[count.index].json
}
