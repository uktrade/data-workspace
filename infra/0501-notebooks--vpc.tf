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

resource "aws_route" "jupyterhub_to_private_with_egress_to_notebooks" {
  count = length(var.aws_availability_zones)

  route_table_id            = aws_route_table.private_with_egress.id
  destination_cidr_block    = aws_subnet.private_without_egress.*.cidr_block[count.index]
  vpc_peering_connection_id = aws_vpc_peering_connection.jupyterhub.id
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
