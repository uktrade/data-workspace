resource "aws_s3_bucket" "matchbox_dev" {
  count  = var.matchbox_on && var.matchbox_dev_mode_on ? 1 : 0
  bucket = var.matchbox_s3_dev_artefacts
}

resource "aws_s3_bucket_server_side_encryption_configuration" "matchbox_dev_encryption" {
  count  = var.matchbox_on && var.matchbox_dev_mode_on ? 1 : 0
  bucket = aws_s3_bucket.matchbox_dev[count.index].id

  rule {
    bucket_key_enabled = false
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket" "matchbox_s3_cache" {
  # count  = length(var.matchbox_instances)
  count  = var.matchbox_on ? 1 : 0
  bucket = "${var.matchbox_s3_cache}-${var.matchbox_instances[count.index]}"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "matchbox_s3_cache_encryption" {
  count  = var.matchbox_on ? 1 : 0
  bucket = aws_s3_bucket.matchbox_s3_cache[count.index].id

  rule {
    bucket_key_enabled = false
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "matchbox" {
  count  = var.matchbox_on ? length(var.matchbox_instances) : 0
  bucket = aws_s3_bucket.matchbox_s3_cache[count.index].id
  policy = data.aws_iam_policy_document.matchbox[count.index].json
}

data "aws_iam_policy_document" "matchbox" {
  count = length(var.matchbox_instances)
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
      "arn:aws:s3:::${aws_s3_bucket.matchbox_s3_cache[count.index].id}/*",
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
