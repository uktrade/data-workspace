resource "aws_vpc_peering_connection" "jupyterhub" {
  peer_vpc_id = aws_vpc.notebooks.id
  vpc_id      = aws_vpc.main.id
  auto_accept = true

  accepter {
    allow_remote_vpc_dns_resolution = false
  }

  requester {
    allow_remote_vpc_dns_resolution = false
  }

  tags = {
    Name = "${var.prefix}"
  }
}

resource "aws_vpc" "notebooks" {
  cidr_block = var.vpc_notebooks_cidr

  enable_dns_support   = false
  enable_dns_hostnames = false

  tags = {
    Name = "${var.prefix}-notebooks"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_flow_log" "notebooks" {
  log_destination = aws_cloudwatch_log_group.vpc_main_flow_log.arn
  iam_role_arn    = aws_iam_role.vpc_notebooks_flow_log.arn
  vpc_id          = aws_vpc.notebooks.id
  traffic_type    = "ALL"
}

resource "aws_cloudwatch_log_group" "vpc_notebooks_flow_log" {
  name              = "${var.prefix}-vpc-notebooks-flow-log"
  retention_in_days = "3653"
}

resource "aws_iam_role" "vpc_notebooks_flow_log" {
  name               = "${var.prefix}-vpc-notebooks-flow-log"
  assume_role_policy = data.aws_iam_policy_document.vpc_notebooks_flow_log_vpc_flow_logs_assume_role.json
}

data "aws_iam_policy_document" "vpc_notebooks_flow_log_vpc_flow_logs_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.prefix}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_dhcp_options" "main" {
  domain_name_servers = ["AmazonProvidedDNS"]
  domain_name         = "eu-west-2.compute.internal"

  tags = {
    Name = "${var.prefix}"
  }
}

resource "aws_vpc_dhcp_options_association" "main" {
  vpc_id          = aws_vpc.main.id
  dhcp_options_id = aws_vpc_dhcp_options.main.id
}

resource "aws_flow_log" "main" {
  log_destination = aws_cloudwatch_log_group.vpc_main_flow_log.arn
  iam_role_arn    = aws_iam_role.vpc_main_flow_log.arn
  vpc_id          = aws_vpc.main.id
  traffic_type    = "ALL"
}

resource "aws_cloudwatch_log_group" "vpc_main_flow_log" {
  name              = "${var.prefix}-vpc-main-flow-log"
  retention_in_days = "3653"
}

resource "aws_iam_role" "vpc_main_flow_log" {
  name               = "${var.prefix}-vpc-main-flow-log"
  assume_role_policy = data.aws_iam_policy_document.vpc_main_flow_log_vpc_flow_logs_assume_role.json
}

data "aws_iam_policy_document" "vpc_main_flow_log_vpc_flow_logs_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "vpc_main_flow_log" {
  name   = "${var.prefix}-vpc-main-flow-log"
  role   = aws_iam_role.vpc_main_flow_log.id
  policy = data.aws_iam_policy_document.vpc_main_flow_log.json
}

data "aws_iam_policy_document" "vpc_main_flow_log" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]

    resources = [
      "${aws_cloudwatch_log_group.vpc_main_flow_log.arn}:*",
    ]
  }
}

resource "aws_subnet" "public" {
  count             = length(var.aws_availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, var.subnets_num_bits, count.index)
  availability_zone = var.aws_availability_zones[count.index]

  tags = {
    Name = "${var.prefix}-public-${var.aws_availability_zones_short[count.index]}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_subnet" "private_with_egress" {
  count      = length(var.aws_availability_zones)
  vpc_id     = aws_vpc.main.id
  cidr_block = cidrsubnet(aws_vpc.main.cidr_block, var.subnets_num_bits, length(var.aws_availability_zones) + count.index)

  availability_zone = var.aws_availability_zones[count.index]

  tags = {
    Name = "${var.prefix}-private-with-egress-${var.aws_availability_zones_short[count.index]}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_subnet" "public_whitelisted_ingress" {
  count      = length(var.aws_availability_zones)
  vpc_id     = aws_vpc.main.id
  cidr_block = cidrsubnet(aws_vpc.main.cidr_block, var.subnets_num_bits, length(var.aws_availability_zones) * 2 + count.index)

  availability_zone = var.aws_availability_zones[count.index]

  tags = {
    Name = "${var.prefix}-public-whitelisted-ingress-${var.aws_availability_zones_short[count.index]}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route_table_association" "public_whitelisted_ingress" {
  count          = length(var.aws_availability_zones)
  subnet_id      = aws_subnet.public_whitelisted_ingress.*.id[count.index]
  route_table_id = aws_route_table.public.id
}

resource "aws_subnet" "private_without_egress" {
  count      = length(var.aws_availability_zones)
  vpc_id     = aws_vpc.notebooks.id
  cidr_block = cidrsubnet(aws_vpc.notebooks.cidr_block, var.vpc_notebooks_subnets_num_bits, count.index)

  availability_zone = var.aws_availability_zones[count.index]

  tags = {
    Name = "${var.prefix}-private-without-egress-${var.aws_availability_zones_short[count.index]}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.prefix}-public"
  }
}

resource "aws_route_table_association" "jupyterhub_public" {
  count          = length(var.aws_availability_zones)
  subnet_id      = aws_subnet.public.*.id[count.index]
  route_table_id = aws_route_table.public.id
}

resource "aws_route" "public_internet_gateway_ipv4" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route_table" "private_with_egress" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.prefix}-private-with-egress"
  }
}

resource "aws_route_table_association" "jupyterhub_private_with_egress" {
  count          = length(var.aws_availability_zones)
  subnet_id      = aws_subnet.private_with_egress.*.id[count.index]
  route_table_id = aws_route_table.private_with_egress.id
}

resource "aws_route" "jupyterhub_to_private_with_egress_to_notebooks" {
  count = length(var.aws_availability_zones)

  route_table_id            = aws_route_table.private_with_egress.id
  destination_cidr_block    = aws_subnet.private_without_egress.*.cidr_block[count.index]
  vpc_peering_connection_id = aws_vpc_peering_connection.jupyterhub.id
}

resource "aws_route" "private_with_egress_nat_gateway_ipv4" {
  route_table_id         = aws_route_table.private_with_egress.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main.id
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.prefix}"
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat_gateway.id
  subnet_id     = aws_subnet.public.*.id[0]

  tags = {
    Name = "${var.prefix}"
  }
}

resource "aws_eip" "nat_gateway" {
  vpc = true
}

resource "aws_route_table" "private_without_egress" {
  vpc_id = aws_vpc.notebooks.id
  tags = {
    Name = "${var.prefix}-private-without-egress"
  }
}

resource "aws_route" "private_without_egress_to_jupyterhub" {
  count = length(var.aws_availability_zones)

  route_table_id            = aws_route_table.private_without_egress.id
  destination_cidr_block    = aws_subnet.private_with_egress.*.cidr_block[count.index]
  vpc_peering_connection_id = aws_vpc_peering_connection.jupyterhub.id
}

resource "aws_route_table_association" "jupyterhub_private_without_egress" {
  count          = length(var.aws_availability_zones)
  subnet_id      = aws_subnet.private_without_egress.*.id[count.index]
  route_table_id = aws_route_table.private_without_egress.id
}

resource "aws_service_discovery_private_dns_namespace" "jupyterhub" {
  name        = "jupyterhub"
  description = "jupyterhub"
  vpc         = aws_vpc.main.id
}

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

resource "aws_flow_log" "datasets" {
  log_destination_type = "s3"
  log_destination      = "arn:aws:s3:::flowlog-${data.aws_caller_identity.aws_caller_identity.account_id}/${aws_vpc.datasets.id}"
  vpc_id               = aws_vpc.datasets.id
  traffic_type         = "ALL"
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

resource "aws_route" "pcx_datasets_to_paas" {
  count                     = var.paas_cidr_block != "" ? 1 : 0
  route_table_id            = aws_route_table.datasets.id
  destination_cidr_block    = var.paas_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.datasets_to_paas[0].id
}

resource "aws_route" "pcx_datasets_to_main" {
  route_table_id            = aws_route_table.datasets.id
  destination_cidr_block    = aws_vpc.main.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.datasets_to_main.id
}

resource "aws_route" "pcx_datasets_to_notebooks" {
  route_table_id            = aws_route_table.datasets.id
  destination_cidr_block    = aws_vpc.notebooks.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.datasets_to_notebooks.id
}

resource "aws_route" "pcx_private_with_egress_to_datasets" {
  route_table_id            = aws_route_table.private_with_egress.id
  destination_cidr_block    = aws_vpc.datasets.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.datasets_to_main.id
}

resource "aws_route" "pcx_datasets_to_private_without_egress" {
  route_table_id            = aws_route_table.private_without_egress.id
  destination_cidr_block    = aws_vpc.datasets.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.datasets_to_notebooks.id
}

resource "aws_subnet" "datasets" {
  count      = length(var.aws_availability_zones)
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
  count          = length(var.aws_availability_zones)
  subnet_id      = aws_subnet.datasets.*.id[count.index]
  route_table_id = aws_route_table.datasets.id
}

resource "aws_subnet" "datasets_quicksight" {
  vpc_id     = aws_vpc.datasets.id
  cidr_block = var.quicksight_cidr_block

  availability_zone = var.quicksight_subnet_availability_zone

  tags = {
    Name = "${var.prefix}-datasets-quicksight"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route_table_association" "datasets_quicksight" {
  subnet_id      = aws_subnet.datasets_quicksight.id
  route_table_id = aws_route_table.datasets.id
}

resource "aws_vpc_endpoint" "datasets_s3_endpoint" {
  vpc_id       = aws_vpc.datasets.id
  service_name = "com.amazonaws.eu-west-2.s3"
  route_table_ids = [aws_route_table.datasets.id]
  tags = {
    Environment = var.prefix
    Name = "datasets-s3-endpoint"
  }
}

resource "aws_vpc_endpoint" "datasets_ec2_endpoint" {
  vpc_id       = aws_vpc.datasets.id
  service_name = "com.amazonaws.eu-west-2.ec2"
  vpc_endpoint_type = "Interface"
  subnet_ids = aws_subnet.datasets.*.id
  security_group_ids = [aws_security_group.datasets_endpoints.id]
  tags = {
    Environment = var.prefix
    Name = "datasets-ec2-endpoint"
  }
  private_dns_enabled = true
  policy = data.aws_iam_policy_document.aws_datasets_endpoint_ec2.json
}

data "aws_iam_policy_document" "aws_datasets_endpoint_ec2" {

  statement {
    principals {
      type        = "AWS"
      identifiers = ["${aws_iam_role.arango_ec2.arn}"]
    }

    actions = [
      "ec2:attachVolume",
    ]

    resources = [
      "arn:aws:sts::${data.aws_caller_identity.aws_caller_identity.account_id}:assumed-role/data-workspace-dev-a-arango-ec2/*",
      "arn:aws:ec2:eu-west-2:${data.aws_caller_identity.aws_caller_identity.account_id}:instance/*",
      "${aws_ebs_volume.arango.arn}"
    ]
  }
}

resource "aws_vpc_endpoint" "datasets_ec2messages_endpoint" {
  vpc_id       = aws_vpc.datasets.id
  service_name = "com.amazonaws.eu-west-2.ec2messages"
  vpc_endpoint_type = "Interface"
  subnet_ids = aws_subnet.datasets.*.id
  security_group_ids = [aws_security_group.datasets_endpoints.id]
  tags = {
    Environment = var.prefix
    Name = "datasets-ec2messages-endpoint"
  }
  private_dns_enabled = true
  policy = data.aws_iam_policy_document.aws_datasets_endpoint_ssm.json
}

resource "aws_vpc_endpoint" "datasets_ssm_endpoint" {
  vpc_id       = aws_vpc.datasets.id
  service_name = "com.amazonaws.eu-west-2.ssm"
  vpc_endpoint_type = "Interface"
  subnet_ids = aws_subnet.datasets.*.id
  security_group_ids = [aws_security_group.datasets_endpoints.id]
  tags = {
    Environment = var.prefix
    Name = "datasets-ssm-endpoint"
  }
  private_dns_enabled = true
  policy = data.aws_iam_policy_document.aws_datasets_endpoint_ssm.json
}

resource "aws_vpc_endpoint" "datasets_ssmmessages_endpoint" {
  vpc_id       = aws_vpc.datasets.id
  service_name = "com.amazonaws.eu-west-2.ssmmessages"
  vpc_endpoint_type = "Interface"
  subnet_ids = aws_subnet.datasets.*.id
  security_group_ids = [aws_security_group.datasets_endpoints.id]
  tags = {
    Environment = var.prefix
    Name = "datasets-ssmmessages-endpoint"
  }
  private_dns_enabled = true
  policy = data.aws_iam_policy_document.aws_datasets_endpoint_ssm.json
}

data "aws_iam_policy_document" "aws_datasets_endpoint_ssm" {

  statement {
    principals {
      type        = "AWS"
      identifiers = ["${aws_iam_role.arango_ec2.arn}"]
    }

    actions = [
      "*"
    ]

    resources = [
      "arn:aws:*:${data.aws_region.aws_region.name}:${data.aws_caller_identity.aws_caller_identity.account_id}:*"
    ]
  }
}

resource "aws_vpc_endpoint" "datasets_ecs_endpoint" {
  vpc_id       = aws_vpc.datasets.id
  service_name = "com.amazonaws.eu-west-2.ecs"
  vpc_endpoint_type = "Interface"
  subnet_ids = aws_subnet.datasets.*.id
  security_group_ids = [aws_security_group.datasets_endpoints.id]
  tags = {
    Environment = var.prefix
    Name = "datasets-ecs-endpoint"
  }
  private_dns_enabled = true
  policy = data.aws_iam_policy_document.aws_datasets_endpoint_ecs.json
}

resource "aws_vpc_endpoint" "datasets_ecs_agent_endpoint" {
  vpc_id       = aws_vpc.datasets.id
  service_name = "com.amazonaws.eu-west-2.ecs-agent"
  vpc_endpoint_type = "Interface"
  subnet_ids = aws_subnet.datasets.*.id
  security_group_ids = [aws_security_group.datasets_endpoints.id]
  tags = {
    Environment = var.prefix
    Name = "datasets-ecs-agent-endpoint"
  }
  private_dns_enabled = true
  policy = data.aws_iam_policy_document.aws_datasets_endpoint_ecs.json
}

resource "aws_vpc_endpoint" "datasets_ecs_telemetry_endpoint" {
  vpc_id       = aws_vpc.datasets.id
  service_name = "com.amazonaws.eu-west-2.ecs-telemetry"
  vpc_endpoint_type = "Interface"
  subnet_ids = aws_subnet.datasets.*.id
  security_group_ids = [aws_security_group.datasets_endpoints.id]
  tags = {
    Environment = var.prefix
    Name = "datasets-ecs-telemetry-endpoint"
  }
  private_dns_enabled = true
  policy = data.aws_iam_policy_document.aws_datasets_endpoint_ecs.json
}

data "aws_iam_policy_document" "aws_datasets_endpoint_ecs" {

  statement {
    principals {
      type        = "AWS"
      identifiers = ["${aws_iam_role.arango_ec2.arn}"]
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

  statement {
    principals {
      type        = "AWS"
      identifiers = ["${aws_iam_role.arango_ec2.arn}"]
    }
    actions = [
      "*"
    ]

    resources = [
      "*"
    ]
  }
}

resource "aws_vpc_endpoint" "datasets_logs_endpoint" {
  vpc_id       = aws_vpc.datasets.id
  service_name = "com.amazonaws.eu-west-2.logs"
  vpc_endpoint_type = "Interface"
  subnet_ids = aws_subnet.datasets.*.id
  security_group_ids = [aws_security_group.datasets_endpoints.id]
  tags = {
    Environment = var.prefix
    Name = "datasets-logs-endpoint"
  }
  private_dns_enabled = true
  policy = data.aws_iam_policy_document.aws_datasets_endpoint_logs.json
}

data "aws_iam_policy_document" "aws_datasets_endpoint_logs" {

  statement {
    principals {
      type        = "AWS"
      identifiers = ["${aws_iam_role.arango_task_execution.arn}"]
    }

    actions = [
      "*",
    ]

    resources = [
      "*"
    ]
  }
}

resource "aws_vpc_endpoint" "datasets_ecr_api_endpoint" {
  vpc_id       = aws_vpc.datasets.id
  service_name = "com.amazonaws.eu-west-2.ecr.api"
  vpc_endpoint_type = "Interface"
  subnet_ids = aws_subnet.datasets.*.id
  security_group_ids = [aws_security_group.datasets_endpoints.id]
  tags = {
    Environment = var.prefix
    Name = "datasets-ecr-api-endpoint"
  }
  private_dns_enabled = true
  policy = data.aws_iam_policy_document.aws_datasets_endpoint_ecr.json
}

resource "aws_vpc_endpoint" "datasets_ecr_dkr_endpoint" {
  vpc_id       = aws_vpc.datasets.id
  service_name = "com.amazonaws.eu-west-2.ecr.dkr"
  vpc_endpoint_type = "Interface"
  subnet_ids = aws_subnet.datasets.*.id
  security_group_ids = [aws_security_group.datasets_endpoints.id]
  tags = {
    Environment = var.prefix
    Name = "datasets-ecr-dkr-endpoint"
  }
  private_dns_enabled = true
  policy = data.aws_iam_policy_document.aws_datasets_endpoint_ecr.json
}


data "aws_iam_policy_document" "aws_datasets_endpoint_ecr" {
  # Contains policies for both ECR and DKR endpoints, as recommended

  statement {
    principals {
      type        = "AWS"
      identifiers = ["${aws_iam_role.arango_task.arn}"]
    }

    actions = [
      "ecr:DescribeImages",
      "ecr:BatchGetImage",
      "ecr:PutImage",
    ]

    resources = [
      "${aws_ecr_repository.user_provided.arn}",
    ]
  }

  statement {
    principals {
      type        = "AWS"
      identifiers = ["${aws_iam_role.arango_task.arn}"]
    }

    actions = [
      "ecs:DescribeTaskDefinition",
    ]

    resources = [
      "*",
    ]
  }

  statement {
    principals {
      type        = "AWS"
      identifiers = ["${aws_iam_role.arango_task.arn}"]
    }

    actions = [
      "ecs:RegisterTaskDefinition",
    ]

    resources = [
      "*",
    ]
  }

  statement {
    principals {
      type        = "AWS"
      identifiers = ["${aws_iam_role.arango_task.arn}"]
    }

    actions = [
      "ecs:StopTask",
    ]

    condition {
      test     = "ArnEquals"
      variable = "ecs:cluster"
      values = [
        "arn:aws:ecs:${data.aws_region.aws_region.name}:${data.aws_caller_identity.aws_caller_identity.account_id}:cluster/${aws_ecs_cluster.main_cluster.name}",
      ]
    }

    resources = [
      "arn:aws:ecs:${data.aws_region.aws_region.name}:${data.aws_caller_identity.aws_caller_identity.account_id}:task/*",
    ]
  }

  statement {
    principals {
      type        = "AWS"
      identifiers = ["${aws_iam_role.arango_task.arn}"]
    }

    actions = [
      "ecs:DescribeTasks",
    ]

    condition {
      test     = "ArnEquals"
      variable = "ecs:cluster"
      values = [
        "arn:aws:ecs:${data.aws_region.aws_region.name}:${data.aws_caller_identity.aws_caller_identity.account_id}:cluster/${aws_ecs_cluster.main_cluster.name}",
      ]
    }

    resources = [
      "arn:aws:ecs:${data.aws_region.aws_region.name}:${data.aws_caller_identity.aws_caller_identity.account_id}:task/*",
    ]
  }

  # For Fargate to start tasks
  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer"
    ]

    resources = [
      "*",
    ]
  }

  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]

    resources = [
      "${aws_ecr_repository.arango.arn}"
    ]
  }
}