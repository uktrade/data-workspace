resource "aws_vpc" "datasets" {
  cidr_block = var.vpc_datasets_cidr

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.prefix}-datasets"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_flow_log" "datasets" {
  log_destination_type = "s3"
  log_destination      = "arn:aws:s3:::flowlog-${data.aws_caller_identity.aws_caller_identity.account_id}/${aws_vpc.datasets.id}"
  vpc_id               = aws_vpc.datasets.id
  traffic_type         = "ALL"
}

resource "aws_route_table" "datasets" {
  vpc_id = aws_vpc.datasets.id
  tags = {
    Name = "${var.prefix}-datasets"
  }
}

resource "aws_main_route_table_association" "datasets" {
  vpc_id         = aws_vpc.datasets.id
  route_table_id = aws_route_table.datasets.id
}

resource "aws_subnet" "datasets" {
  count      = length(var.dataset_subnets_availability_zones)
  vpc_id     = aws_vpc.datasets.id
  cidr_block = var.datasets_subnet_cidr_blocks[count.index]

  availability_zone = var.dataset_subnets_availability_zones[count.index]

  tags = {
    Name = "${var.prefix}-datasets-${var.aws_availability_zones_short[count.index]}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route_table_association" "datasets" {
  count          = length(var.dataset_subnets_availability_zones)
  subnet_id      = aws_subnet.datasets.*.id[count.index]
  route_table_id = aws_route_table.datasets.id
}

resource "aws_route53_resolver_firewall_domain_list" "datasets_amazonaws" {
  name    = "${var.prefix}-datasets-amazonaws"
  domains = ["*.amazonaws.com."]
}

resource "aws_route53_resolver_firewall_domain_list" "datasets_all" {
  name    = "${var.prefix}-datasets-all-domains"
  domains = ["*."]
}

resource "aws_route53_resolver_firewall_rule_group" "datasets_allow_amazonaws_block_otherwise" {
  name = "${var.prefix}-datasets-allow-amazonaws-block-otherwise"
}

resource "aws_route53_resolver_firewall_rule_group_association" "datasets_allow_amazonaws_block_otherwise" {
  name                   = "${var.prefix}-datasets-allow-amazonaws-block-otherwise"
  firewall_rule_group_id = aws_route53_resolver_firewall_rule_group.datasets_allow_amazonaws_block_otherwise.id
  priority               = 1000
  vpc_id                 = aws_vpc.datasets.id
}

resource "aws_route53_resolver_firewall_rule" "datasets_allow_amazonaws" {
  name                    = "${var.prefix}-allow-amazonaws"
  action                  = "ALLOW"
  firewall_domain_list_id = aws_route53_resolver_firewall_domain_list.datasets_amazonaws.id
  firewall_rule_group_id  = aws_route53_resolver_firewall_rule_group.datasets_allow_amazonaws_block_otherwise.id
  priority                = 100
}

resource "aws_route53_resolver_firewall_rule" "datasets_block_otherwise" {
  name                    = "${var.prefix}-block-all"
  action                  = "BLOCK"
  block_response          = "NXDOMAIN"
  firewall_domain_list_id = aws_route53_resolver_firewall_domain_list.datasets_all.id
  firewall_rule_group_id  = aws_route53_resolver_firewall_rule_group.datasets_allow_amazonaws_block_otherwise.id
  priority                = 200
}

resource "aws_vpc_peering_connection" "datasets_to_paas" {
  count       = var.paas_cidr_block != "" ? 1 : 0
  peer_vpc_id = var.paas_vpc_id
  vpc_id      = aws_vpc.datasets.id
  auto_accept = true

  accepter {
    allow_remote_vpc_dns_resolution = false
  }

  tags = {
    Name = "${var.prefix}-datasets-to-paas"
  }
}

resource "aws_vpc_peering_connection" "datasets_to_main" {
  peer_vpc_id = aws_vpc.datasets.id
  vpc_id      = aws_vpc.main.id
  auto_accept = true

  accepter {
    allow_remote_vpc_dns_resolution = false
  }

  requester {
    allow_remote_vpc_dns_resolution = false
  }

  tags = {
    Name = "${var.prefix}-datasets-to-main"
  }
}

resource "aws_vpc_peering_connection" "datasets_to_notebooks" {
  peer_vpc_id = aws_vpc.datasets.id
  vpc_id      = aws_vpc.notebooks.id
  auto_accept = true

  accepter {
    allow_remote_vpc_dns_resolution = false
  }

  requester {
    allow_remote_vpc_dns_resolution = false
  }

  tags = {
    Name = "${var.prefix}-datasets-to-notebooks"
  }
}

resource "aws_vpc_endpoint" "datasets_s3_endpoint" {
  count           = var.arango_on ? 1 : 0
  vpc_id          = aws_vpc.datasets.id
  service_name    = "com.amazonaws.eu-west-2.s3"
  route_table_ids = [aws_route_table.datasets.id]
  tags = {
    Environment = var.prefix
    Name        = "datasets-s3-endpoint"
  }
  policy = data.aws_iam_policy_document.datasets_s3_endpoint.json
}

data "aws_iam_policy_document" "datasets_s3_endpoint" {
  dynamic "statement" {
    for_each = var.arango_on ? [0] : []
    content {
      principals {
        type        = "AWS"
        identifiers = ["*"]
      }

      actions = [
        "s3:GetObject"
      ]

      resources = [
        "arn:aws:s3:::prod-${data.aws_region.aws_region.name}-starport-layer-bucket/*",
      ]
    }
  }
}

resource "aws_vpc_endpoint" "datasets_ec2_endpoint" {
  count              = var.arango_on ? 1 : 0
  vpc_id             = aws_vpc.datasets.id
  service_name       = "com.amazonaws.eu-west-2.ec2"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = aws_subnet.datasets.*.id
  security_group_ids = [aws_security_group.datasets_endpoints.id]
  tags = {
    Environment = var.prefix
    Name        = "datasets-ec2-endpoint"
  }
  private_dns_enabled = true
  policy              = data.aws_iam_policy_document.aws_datasets_endpoint_ec2.json
}

data "aws_iam_policy_document" "aws_datasets_endpoint_ec2" {
  dynamic "statement" {
    for_each = var.arango_on ? [0] : []
    content {
      principals {
        type        = "AWS"
        identifiers = ["${aws_iam_role.arango_ec2[0].arn}"]
      }

      actions = [
        "ec2:attachVolume",
      ]

      resources = [
        "arn:aws:ec2:eu-west-2:${data.aws_caller_identity.aws_caller_identity.account_id}:instance/*",
        "${aws_ebs_volume.arango[0].arn}"
      ]
    }
  }
}

resource "aws_vpc_endpoint" "datasets_ec2messages_endpoint" {
  count              = var.arango_on ? 1 : 0
  vpc_id             = aws_vpc.datasets.id
  service_name       = "com.amazonaws.eu-west-2.ec2messages"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = aws_subnet.datasets.*.id
  security_group_ids = [aws_security_group.datasets_endpoints.id]
  tags = {
    Environment = var.prefix
    Name        = "datasets-ec2messages-endpoint"
  }
  private_dns_enabled = true
  policy              = data.aws_iam_policy_document.aws_datasets_endpoint_ssm.json
}

resource "aws_vpc_endpoint" "datasets_ssm_endpoint" {
  count              = var.arango_on ? 1 : 0
  vpc_id             = aws_vpc.datasets.id
  service_name       = "com.amazonaws.eu-west-2.ssm"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = aws_subnet.datasets.*.id
  security_group_ids = [aws_security_group.datasets_endpoints.id]
  tags = {
    Environment = var.prefix
    Name        = "datasets-ssm-endpoint"
  }
  private_dns_enabled = true
  policy              = data.aws_iam_policy_document.aws_datasets_endpoint_ssm.json
}

resource "aws_vpc_endpoint" "datasets_ssmmessages_endpoint" {
  count              = var.arango_on ? 1 : 0
  vpc_id             = aws_vpc.datasets.id
  service_name       = "com.amazonaws.eu-west-2.ssmmessages"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = aws_subnet.datasets.*.id
  security_group_ids = [aws_security_group.datasets_endpoints.id]
  tags = {
    Environment = var.prefix
    Name        = "datasets-ssmmessages-endpoint"
  }
  private_dns_enabled = true
  policy              = data.aws_iam_policy_document.aws_datasets_endpoint_ssm.json
}

data "aws_iam_policy_document" "aws_datasets_endpoint_ssm" {
  dynamic "statement" {
    for_each = var.arango_on ? [0] : []
    content {
      principals {
        type        = "AWS"
        identifiers = ["${aws_iam_role.arango_ec2[0].arn}"]
      }

      actions = [
        "*"
      ]

      resources = [
        "arn:aws:*:${data.aws_region.aws_region.name}:${data.aws_caller_identity.aws_caller_identity.account_id}:*"
      ]
    }
  }
}

resource "aws_vpc_endpoint" "datasets_ecs_endpoint" {
  count              = var.arango_on ? 1 : 0
  vpc_id             = aws_vpc.datasets.id
  service_name       = "com.amazonaws.eu-west-2.ecs"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = aws_subnet.datasets.*.id
  security_group_ids = [aws_security_group.datasets_endpoints.id]
  tags = {
    Environment = var.prefix
    Name        = "datasets-ecs-endpoint"
  }
  private_dns_enabled = true
  policy              = data.aws_iam_policy_document.aws_datasets_endpoint_ecs.json
}

resource "aws_vpc_endpoint" "datasets_ecs_agent_endpoint" {
  count              = var.arango_on ? 1 : 0
  vpc_id             = aws_vpc.datasets.id
  service_name       = "com.amazonaws.eu-west-2.ecs-agent"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = aws_subnet.datasets.*.id
  security_group_ids = [aws_security_group.datasets_endpoints.id]
  tags = {
    Environment = var.prefix
    Name        = "datasets-ecs-agent-endpoint"
  }
  private_dns_enabled = true
  policy              = data.aws_iam_policy_document.aws_datasets_endpoint_ecs.json
}

resource "aws_vpc_endpoint" "datasets_ecs_telemetry_endpoint" {
  count              = var.arango_on ? 1 : 0
  vpc_id             = aws_vpc.datasets.id
  service_name       = "com.amazonaws.eu-west-2.ecs-telemetry"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = aws_subnet.datasets.*.id
  security_group_ids = [aws_security_group.datasets_endpoints.id]
  tags = {
    Environment = var.prefix
    Name        = "datasets-ecs-telemetry-endpoint"
  }
  private_dns_enabled = true
  policy              = data.aws_iam_policy_document.aws_datasets_endpoint_ecs.json
}

data "aws_iam_policy_document" "aws_datasets_endpoint_ecs" {
  dynamic "statement" {
    for_each = var.arango_on ? [0] : []
    content {
      principals {
        type        = "AWS"
        identifiers = ["${aws_iam_role.arango_ec2[0].arn}"]
      }

      actions = [
        "*"
      ]

      resources = [
        "*"
      ]
      condition {
        test     = "ArnEquals"
        variable = "ecs:cluster"
        values = [
          "arn:aws:ecs:${data.aws_region.aws_region.name}:${data.aws_caller_identity.aws_caller_identity.account_id}:cluster/${aws_ecs_cluster.main_cluster.name}"
        ]
      }
    }
  }

  dynamic "statement" {
    for_each = var.arango_on ? [0] : []
    content {
      principals {
        type        = "AWS"
        identifiers = ["${aws_iam_role.arango_ec2[0].arn}"]
      }
      actions = [
        "*"
      ]

      resources = [
        "*"
      ]
    }
  }
}

resource "aws_vpc_endpoint" "datasets_logs_endpoint" {
  count              = var.arango_on ? 1 : 0
  vpc_id             = aws_vpc.datasets.id
  service_name       = "com.amazonaws.eu-west-2.logs"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = aws_subnet.datasets.*.id
  security_group_ids = [aws_security_group.datasets_endpoints.id]
  tags = {
    Environment = var.prefix
    Name        = "datasets-logs-endpoint"
  }
  private_dns_enabled = true
  policy              = data.aws_iam_policy_document.aws_datasets_endpoint_logs.json
}

data "aws_iam_policy_document" "aws_datasets_endpoint_logs" {

  dynamic "statement" {
    for_each = var.arango_on ? [0] : []
    content {
      principals {
        type        = "AWS"
        identifiers = ["${aws_iam_role.arango_task_execution[0].arn}"]
      }

      actions = [
        "*",
      ]

      resources = [
        "*"
      ]
    }
  }
}

resource "aws_vpc_endpoint" "datasets_ecr_api_endpoint" {
  count              = var.arango_on ? 1 : 0
  vpc_id             = aws_vpc.datasets.id
  service_name       = "com.amazonaws.eu-west-2.ecr.api"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = aws_subnet.datasets.*.id
  security_group_ids = [aws_security_group.datasets_endpoints.id]
  tags = {
    Environment = var.prefix
    Name        = "datasets-ecr-api-endpoint"
  }
  private_dns_enabled = true
  policy              = data.aws_iam_policy_document.aws_datasets_endpoint_ecr.json
}

resource "aws_vpc_endpoint" "datasets_ecr_dkr_endpoint" {
  count              = var.arango_on ? 1 : 0
  vpc_id             = aws_vpc.datasets.id
  service_name       = "com.amazonaws.eu-west-2.ecr.dkr"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = aws_subnet.datasets.*.id
  security_group_ids = [aws_security_group.datasets_endpoints.id]
  tags = {
    Environment = var.prefix
    Name        = "datasets-ecr-dkr-endpoint"
  }
  private_dns_enabled = true
  policy              = data.aws_iam_policy_document.aws_datasets_endpoint_ecr.json
}
