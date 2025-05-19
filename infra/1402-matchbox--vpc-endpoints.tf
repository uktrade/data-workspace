resource "aws_vpc_endpoint" "matchbox_ecr_api_endpoint" {
  count = var.matchbox_on ? 1 : 0

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
  count = var.matchbox_on ? 1 : 0

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
  count = var.matchbox_on ? 1 : 0

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
  count = var.matchbox_on ? 1 : 0

  vpc_id              = aws_vpc.matchbox[0].id
  service_name        = "com.amazonaws.${data.aws_region.aws_region.name}.logs"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = ["${aws_security_group.matchbox_endpoints[0].id}"]
  subnet_ids          = ["${aws_subnet.matchbox_private.*.id[0]}"]
  policy              = data.aws_iam_policy_document.matchbox_cloudwatch_endpoint[0].json
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

resource "aws_security_group_rule" "matchbox_egress_https_to_matchbox_endpoints" {
  count = var.matchbox_on ? 1 : 0

  description              = "egress-https-from-matchbox-service"
  security_group_id        = aws_security_group.matchbox_service[count.index].id
  source_security_group_id = aws_security_group.matchbox_endpoints[0].id

  type      = "egress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "matchbox_egress_https_datadog" {
  count = var.matchbox_on ? 1 : 0

  description       = "egress-https-to-datadog"
  security_group_id = aws_security_group.matchbox_service[count.index].id
  # From https://ip-ranges.datadoghq.eu/
  cidr_blocks = [
    "34.107.147.46/32",
    "34.107.148.131/32",
    "34.107.178.244/32",
    "34.107.236.155/32",
    "34.110.210.251/32",
    "34.117.189.27/32",
    "34.117.37.81/32",
    "34.120.15.173/32",
    "34.120.31.75/32",
    "34.120.57.90/32",
    "34.120.77.189/32",
    "34.120.96.217/32",
    "34.149.115.128/26",
    "34.149.135.19/32",
    "34.149.169.145/32",
    "34.149.206.161/32",
    "34.149.254.123/32",
    "34.149.49.28/32",
    "34.149.78.213/32",
    "34.160.168.175/32",
    "34.160.186.117/32",
    "34.160.253.227/32",
    "34.160.51.118/32",
    "34.95.101.191/32",
    "34.96.71.221/32",
    "34.98.110.196/32",
    "34.98.83.239/32",
    "34.98.95.189/32",
    "35.190.39.146/32",
    "35.190.78.95/32",
    "35.190.9.84/32",
    "35.201.126.123/32",
    "35.227.218.104/32",
    "35.227.223.199/32",
    "35.241.39.98/32",
    "35.244.140.126/32",
    "35.244.180.206/32",
    "35.244.221.148/32",
  ]

  type      = "egress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "matchbox_endpoints_https_ingress_from_matchbox_service" {
  count = var.matchbox_on ? 1 : 0

  description              = "ingress-matchbox-endpoints"
  security_group_id        = aws_security_group.matchbox_endpoints[0].id
  source_security_group_id = aws_security_group.matchbox_service[count.index].id

  type      = "ingress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "matchbox_service_egress_udp_to_dns_rewrite_proxy" {
  count = var.matchbox_on ? 1 : 0

  description       = "egress-dns-to-dns-rewrite-proxy"
  security_group_id = aws_security_group.matchbox_service[count.index].id
  cidr_blocks       = ["${aws_subnet.private_with_egress.*.cidr_block[0]}"]

  type      = "egress"
  from_port = "53"
  to_port   = "53"
  protocol  = "udp"
}

resource "aws_security_group_rule" "matchbox_db_https_ingress_from_matchbox_service" {
  count = var.matchbox_on ? 1 : 0

  description              = "ingress-https-to-matchbox-db"
  security_group_id        = aws_security_group.matchbox_db[count.index].id
  source_security_group_id = aws_security_group.matchbox_service[count.index].id

  type      = "ingress"
  from_port = local.matchbox_db_port
  to_port   = local.matchbox_db_port
  protocol  = "tcp"
}
