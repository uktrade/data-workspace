# One bucket is used over several, to maximise chance of connection resuse
# since path-style access is being phased out

resource "aws_s3_bucket" "gitlab" {
  count  = var.gitlab_on ? 1 : 0
  bucket = var.gitlab_bucket

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_policy" "gitlab" {
  count  = var.gitlab_on ? 1 : 0
  bucket = aws_s3_bucket.gitlab[count.index].id
  policy = data.aws_iam_policy_document.gitlab_bucket[count.index].json
}

data "aws_iam_policy_document" "gitlab_bucket" {
  count = var.gitlab_on ? 1 : 0

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
      "arn:aws:s3:::${aws_s3_bucket.gitlab[count.index].id}/*",
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
