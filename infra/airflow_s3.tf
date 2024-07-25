resource "aws_s3_bucket" "airflow" {
  count  = var.airflow_on ? length(var.airflow_dag_processors) : 0
  bucket = "${var.prefix}-${var.airflow_bucket_infix}-${replace(var.airflow_dag_processors[count.index], "_", "-")}"


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
}

resource "aws_iam_access_key" "airflow_s3" {
  count = var.airflow_on ? length(var.airflow_dag_processors) : 0
  user  = aws_iam_user.airflow_s3[count.index].name
}

resource "aws_iam_user" "airflow_s3" {
  count = var.airflow_on ? length(var.airflow_dag_processors) : 0
  name  = aws_s3_bucket.airflow[count.index].id
}

data "aws_iam_policy_document" "airflow_s3" {
  count = var.airflow_on ? length(var.airflow_dag_processors) : 0
  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject"
    ]

    resources = [
      "${aws_s3_bucket.airflow[count.index].arn}/*",
    ]
  }

  statement {
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
    ]

    resources = [
      "${aws_s3_bucket.airflow[count.index].arn}",
    ]
  }
}

resource "aws_iam_user_policy" "airflow_s3" {
  count  = var.airflow_on ? length(var.airflow_dag_processors) : 0
  name   = aws_s3_bucket.airflow[count.index].id
  user   = aws_iam_user.airflow_s3[count.index].name
  policy = data.aws_iam_policy_document.airflow_s3[count.index].json
}

output "airflow_s3_bucket_name" {
  value       = aws_s3_bucket.airflow.*.id
  description = "Name of the bucket used for Airflow ingest"
}

output "airflow_s3_bucket_region" {
  value       = aws_s3_bucket.airflow.*.region
  description = "Region of the bucket used for Airflow ingest"
}

output "airflow_s3_access_key_id" {
  value       = aws_iam_access_key.airflow_s3.*.id
  description = "Name of the Access key ID used for Airflow ingest"
}

output "airflow_s3_access_key_secret" {
  value       = aws_iam_access_key.airflow_s3.*.secret
  description = "Access key secret used for Airflow ingest"
  sensitive   = true
}