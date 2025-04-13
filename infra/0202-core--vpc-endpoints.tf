resource "aws_vpc_endpoint" "main_s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.aws_region.name}.s3"
  vpc_endpoint_type = "Gateway"
}

resource "aws_vpc_endpoint_route_table_association" "main_s3" {
  vpc_endpoint_id = aws_vpc_endpoint.main_s3.id
  route_table_id  = aws_route_table.private_with_egress.id
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.aws_region.name}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  security_group_ids = ["${aws_security_group.ecr_dkr.id}"]
  subnet_ids         = ["${aws_subnet.private_with_egress.*.id[0]}"]

  policy = data.aws_iam_policy_document.aws_vpc_endpoint_ecr.json

  timeouts {}
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.aws_region.name}.ecr.api"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  security_group_ids = ["${aws_security_group.ecr_api.id}"]
  subnet_ids         = ["${aws_subnet.private_with_egress.*.id[0]}"]

  policy = data.aws_iam_policy_document.aws_vpc_endpoint_ecr.json

  timeouts {}
}

data "aws_iam_policy_document" "aws_vpc_endpoint_ecr" {

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

resource "aws_vpc_endpoint" "cloudwatch_logs" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.aws_region.name}.logs"
  vpc_endpoint_type = "Interface"

  security_group_ids = ["${aws_security_group.cloudwatch.id}"]
  subnet_ids         = ["${aws_subnet.private_with_egress.*.id[0]}"]

  policy = data.aws_iam_policy_document.aws_vpc_endpoint_cloudwatch_logs.json

  private_dns_enabled = true
}

data "aws_iam_policy_document" "aws_vpc_endpoint_cloudwatch_logs" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "*",
    ]

    resources = [
      "*",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalAccount"
      values = [
        "${data.aws_caller_identity.aws_caller_identity.account_id}"
      ]
    }
  }
}

resource "aws_vpc_endpoint" "cloudwatch_monitoring" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.aws_region.name}.monitoring"
  vpc_endpoint_type = "Interface"

  security_group_ids = ["${aws_security_group.cloudwatch.id}"]
  subnet_ids         = ["${aws_subnet.private_with_egress.*.id[0]}"]

  policy = data.aws_iam_policy_document.aws_vpc_endpoint_cloudwatch_monitoring.json

  private_dns_enabled = true
}

data "aws_iam_policy_document" "aws_vpc_endpoint_cloudwatch_monitoring" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "*",
    ]

    resources = [
      "*",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalAccount"
      values = [
        "${data.aws_caller_identity.aws_caller_identity.account_id}"
      ]
    }
  }
}

resource "aws_vpc_endpoint" "ecs" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.aws_region.name}.ecs"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = ["${aws_security_group.ecs.id}"]
  subnet_ids          = ["${aws_subnet.private_with_egress.*.id[0]}"]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "sagemaker_runtime_endpoint_main" {
  count              = var.sagemaker_on ? 1 : 0
  vpc_id             = aws_vpc.main.id
  service_name       = "com.amazonaws.eu-west-2.sagemaker.runtime"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = aws_subnet.private_with_egress.*.id
  security_group_ids = [aws_security_group.sagemaker_vpc_endpoints_main[0].id]
  tags = {
    Environment = var.prefix
    Name        = "main-sagemaker-runtime-endpoint"
  }
  private_dns_enabled = true
  policy              = data.aws_iam_policy_document.sagemaker_vpc_endpoint_policy[0].json
}

resource "aws_vpc_endpoint" "sagemaker_api_endpoint_main" {
  count              = var.sagemaker_on ? 1 : 0
  vpc_id             = aws_vpc.main.id
  service_name       = "com.amazonaws.eu-west-2.sagemaker.api"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = aws_subnet.private_with_egress.*.id
  security_group_ids = [aws_security_group.sagemaker_vpc_endpoints_main[0].id]
  tags = {
    Environment = var.prefix
    Name        = "main-sagemaker-api-endpoint"
  }
  private_dns_enabled = true
  policy              = data.aws_iam_policy_document.sagemaker_vpc_endpoint_policy[0].json
}

data "aws_iam_policy_document" "sagemaker_vpc_endpoint_policy" {
  # Prevents access to other AWS accounts through the VPC endpoint. There are policies on the
  # roles themselves that restrict the actions and/or resources

  count = var.sagemaker_on ? 1 : 0
  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "*",
    ]
    resources = [
      "*",
    ]
    condition {
      test     = "StringLike"
      variable = "aws:PrincipalArn"
      values   = ["arn:aws:iam::${data.aws_caller_identity.aws_caller_identity.account_id}:role/*"]
    }
  }
}
