resource "aws_vpc_endpoint" "matchbox_ecr_api_endpoint" {
  count              = var.matchbox_on ? 1 : 0
  vpc_id             = aws_vpc.matchbox[0].id
  service_name       = "com.amazonaws.eu-west-2.ecr.api"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = aws_subnet.matchbox_private.*.id
  security_group_ids = [aws_security_group.matchbox_endpoints[0].id]
  tags = {
    Environment = var.prefix
    Name        = "matchbox-ecr-api-endpoint"
  }
  private_dns_enabled = true
  policy              = data.aws_iam_policy_document.aws_matchbox_endpoint_ecr[0].json
}

resource "aws_vpc_endpoint" "matchbox_ecr_dkr_endpoint" {
  count              = var.matchbox_on ? 1 : 0
  vpc_id             = aws_vpc.matchbox[0].id
  service_name       = "com.amazonaws.${data.aws_region.aws_region.name}.ecr.dkr"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = aws_subnet.matchbox_private.*.id
  security_group_ids = [aws_security_group.matchbox_endpoints[0].id]
  tags = {
    Environment = var.prefix
    Name        = "matchbox-ecr-dkr-endpoint"
  }
  private_dns_enabled = true
  policy              = data.aws_iam_policy_document.aws_matchbox_endpoint_ecr[0].json
}

data "aws_iam_policy_document" "aws_matchbox_endpoint_ecr" {
  count = var.matchbox_on ? 1 : 0

  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalAccount"
      values = [
        "${data.aws_caller_identity.aws_caller_identity.account_id}"
      ]
    }

    actions = [
      "*"
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_vpc_endpoint" "matchbox_endpoint_s3" {
  count             = var.matchbox_on ? 1 : 0
  vpc_id            = aws_vpc.matchbox[0].id
  service_name      = "com.amazonaws.${data.aws_region.aws_region.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.matchbox[0].id]

  tags = {
    Environment = var.prefix
    Name        = "matchbox-s3-endpoint"
  }
}

resource "aws_vpc_endpoint" "matchbox_cloudwatch_logs" {
  count             = var.matchbox_on ? 1 : 0
  vpc_id            = aws_vpc.matchbox[0].id
  service_name      = "com.amazonaws.${data.aws_region.aws_region.name}.logs"
  vpc_endpoint_type = "Interface"

  security_group_ids = ["${aws_security_group.matchbox_endpoints[0].id}"]
  subnet_ids         = ["${aws_subnet.matchbox_private.*.id[0]}"]

  policy = data.aws_iam_policy_document.matchbox_cloudwatch_endpoint[0].json

  private_dns_enabled = true
}

data "aws_iam_policy_document" "matchbox_cloudwatch_endpoint" {
  count = var.matchbox_on ? 1 : 0

  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalAccount"
      values = [
        "${data.aws_caller_identity.aws_caller_identity.account_id}"
      ]
    }

    actions = [
      "*"
    ]

    resources = [
      "*",
    ]
  }
}
