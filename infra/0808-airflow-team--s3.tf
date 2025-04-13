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

data "aws_iam_policy_document" "airflow" {
  count = var.airflow_on ? length(var.airflow_dag_processors) : 0
  statement {
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = [
      "s3:*",
    ]
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.airflow[count.index].id}/*",
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values = [
        "false"
      ]
    }
  }

  dynamic "statement" {
    for_each = length(var.airflow_dag_processors[count.index].assume_roles) > 0 ? [1] : []
    content {
      effect = "Allow"
      sid    = "Allow read access to data flow objects"

      principals {
        type        = "AWS"
        identifiers = var.airflow_dag_processors[count.index].assume_roles
      }

      resources = [for prefix in var.s3_prefixes_for_external_role_copy : "arn:aws:s3:::${aws_s3_bucket.airflow[count.index].id}/${prefix}/*"]

      actions = [
        "s3:GetObject",
        "s3:GetObjectTagging",
        "s3:GetObjectVersion",
        "s3:GetObjectVersionTagging"
      ]
    }
  }
}
