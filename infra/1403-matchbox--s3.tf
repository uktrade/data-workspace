resource "aws_s3_bucket" "matchbox_dev" {
  count = var.matchbox_on && var.matchbox_dev_mode_on ? 1 : 0

  bucket = var.matchbox_s3_dev_artefacts
}

resource "aws_s3_bucket_server_side_encryption_configuration" "matchbox_dev_encryption" {
  count = var.matchbox_on && var.matchbox_dev_mode_on ? 1 : 0

  bucket = aws_s3_bucket.matchbox_dev[count.index].id

  rule {
    bucket_key_enabled = false
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket" "matchbox_s3_cache" {
  count = var.matchbox_on ? 1 : 0

  bucket = "${var.matchbox_s3_cache}-${var.matchbox_environment}"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "matchbox_s3_cache_encryption" {
  count = var.matchbox_on ? 1 : 0

  bucket = aws_s3_bucket.matchbox_s3_cache[count.index].id

  rule {
    bucket_key_enabled = false
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "matchbox" {
  count = var.matchbox_on ? 1 : 0

  bucket = aws_s3_bucket.matchbox_s3_cache[0].id
  policy = data.aws_iam_policy_document.matchbox[count.index].json
}

data "aws_iam_policy_document" "matchbox" {
  count = var.matchbox_on ? 1 : 0

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
      "arn:aws:s3:::${aws_s3_bucket.matchbox_s3_cache[0].id}/*",
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

resource "aws_security_group_rule" "matchbox_egress_https_to_matchbox_s3_endpoint" {
  count = var.matchbox_on ? 1 : 0

  description       = "egress-https-to-s3"
  security_group_id = aws_security_group.matchbox_service[count.index].id
  prefix_list_ids   = [aws_vpc_endpoint.matchbox_endpoint_s3[0].prefix_list_id]

  type      = "egress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "matchbox_db_egress_https_to_matchbox_s3_endpoint" {
  count = var.matchbox_on ? 1 : 0

  description       = "egress-https-to-s3"
  security_group_id = aws_security_group.matchbox_db[count.index].id
  prefix_list_ids   = [aws_vpc_endpoint.matchbox_endpoint_s3[0].prefix_list_id]

  type      = "egress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}
