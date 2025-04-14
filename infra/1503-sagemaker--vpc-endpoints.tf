
resource "aws_vpc_endpoint" "sagemaker_s3" {
  count             = var.sagemaker_on ? 1 : 0
  vpc_id            = aws_vpc.sagemaker[0].id
  service_name      = "com.amazonaws.${data.aws_region.aws_region.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.sagemaker[0].id]
}

resource "aws_vpc_endpoint_route_table_association" "s3_sagemaker" {
  count           = var.sagemaker_on ? 1 : 0
  vpc_endpoint_id = aws_vpc_endpoint.sagemaker_s3[0].id
  route_table_id  = aws_route_table.sagemaker[0].id
}

resource "aws_vpc_endpoint" "sagemaker_ecr_api_endpoint" {
  count              = var.sagemaker_on ? 1 : 0
  vpc_id             = aws_vpc.sagemaker[0].id
  service_name       = "com.amazonaws.eu-west-2.ecr.api"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = aws_subnet.sagemaker_private_without_egress.*.id
  security_group_ids = [aws_security_group.sagemaker_endpoints[0].id]
  tags = {
    Environment = var.prefix
    Name        = "sagemaker-ecr-api-endpoint"
  }
  private_dns_enabled = true
  policy              = data.aws_iam_policy_document.aws_sagemaker_endpoint_ecr[0].json
}

resource "aws_vpc_endpoint" "sagemaker_ecr_dkr_endpoint" {
  count              = var.sagemaker_on ? 1 : 0
  vpc_id             = aws_vpc.sagemaker[0].id
  service_name       = "com.amazonaws.eu-west-2.ecr.dkr"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = aws_subnet.sagemaker_private_without_egress.*.id
  security_group_ids = [aws_security_group.sagemaker_endpoints[0].id]
  tags = {
    Environment = var.prefix
    Name        = "sagemaker-ecr-dkr-endpoint"
  }
  private_dns_enabled = true
  policy              = data.aws_iam_policy_document.aws_sagemaker_endpoint_ecr[0].json
}


data "aws_iam_policy_document" "aws_sagemaker_endpoint_ecr" {
  count = var.sagemaker_on ? 1 : 0
  # Contains policies for both ECR and DKR endpoints, as recommended

  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer"
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_vpc_endpoint" "sns_endpoint_sagemaker" {
  count              = var.sagemaker_on ? 1 : 0
  vpc_id             = aws_vpc.sagemaker[0].id
  service_name       = "com.amazonaws.eu-west-2.sns"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = aws_subnet.sagemaker_private_without_egress.*.id
  security_group_ids = [aws_security_group.sagemaker_endpoints[0].id]
  tags = {
    Environment = var.prefix
    Name        = "sns-endpoint"
  }
  private_dns_enabled = true
  policy              = data.aws_iam_policy_document.sns_endpoint_policy[0].json
}

data "aws_iam_policy_document" "sns_endpoint_policy" {
  count = var.sagemaker_on ? 1 : 0
  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "SNS:Subscribe",
      "SNS:Receive",
      "SNS:Publish",
    ]
    resources = [
      "*"
    ]
  }
}
