resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.notebooks.id
  service_name      = "com.amazonaws.${data.aws_region.aws_region.name}.s3"
  vpc_endpoint_type = "Gateway"

  policy = data.aws_iam_policy_document.aws_vpc_endpoint_s3_notebooks.json

  timeouts {}
}

data "aws_iam_policy_document" "aws_vpc_endpoint_s3_notebooks" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "s3:ListBucket",
    ]
    resources = concat([
      "${aws_s3_bucket.notebooks.arn}",
      ], [
      for bucket in aws_s3_bucket.mlflow : bucket.arn
    ])
  }

  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject"
    ]

    resources = concat([
      "${aws_s3_bucket.notebooks.arn}/*",
      ], [
      for bucket in aws_s3_bucket.mlflow : "${bucket.arn}/*"
    ])
  }

  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
    ]

    resources = [
      for bucket in aws_s3_bucket.mlflow : bucket.arn
    ]
  }

  statement {
    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "arn:aws:s3:::${var.mirrors_data_bucket_name != "" ? var.mirrors_data_bucket_name : var.mirrors_bucket_name}/*",
    ]
  }

  statement {
    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "s3:ListBucket",
    ]

    resources = [
      "arn:aws:s3:::${var.mirrors_data_bucket_name != "" ? var.mirrors_data_bucket_name : var.mirrors_bucket_name}",
    ]
  }

  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "s3:GetObject",
    ]

    resources = [
      # For docker to pull from ECR
      "arn:aws:s3:::prod-${data.aws_region.aws_region.name}-starport-layer-bucket/*",
      # For AWS Linux 2 packages
      "arn:aws:s3:::amazonlinux.*.amazonaws.com/*",
    ]
  }
}
