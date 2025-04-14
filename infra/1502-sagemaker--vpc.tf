resource "aws_vpc" "sagemaker" {
  count = var.sagemaker_on ? 1 : 0

  cidr_block           = var.vpc_sagemaker_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.prefix}-sagemaker"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_subnet" "sagemaker_private_without_egress" {
  count = var.sagemaker_on ? length(var.aws_availability_zones) : 0

  vpc_id            = aws_vpc.sagemaker[0].id
  cidr_block        = cidrsubnet(aws_vpc.sagemaker[0].cidr_block, var.vpc_sagemaker_subnets_num_bits, count.index)
  availability_zone = var.aws_availability_zones[count.index]

  tags = {
    Name = "${var.prefix}-sagemaker-private-without-egress-${var.aws_availability_zones_short[count.index]}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route_table" "sagemaker" {
  count = var.sagemaker_on ? 1 : 0

  vpc_id = aws_vpc.sagemaker[0].id
  tags = {
    Name = "${var.prefix}-sagemaker"
  }
}

resource "aws_main_route_table_association" "sagemaker" {
  count          = var.sagemaker_on ? 1 : 0
  vpc_id         = aws_vpc.sagemaker[0].id
  route_table_id = aws_route_table.sagemaker[0].id
}

resource "aws_route_table_association" "private_without_egress_sagemaker" {
  count          = var.sagemaker_on ? length(var.aws_availability_zones) : 0
  subnet_id      = aws_subnet.sagemaker_private_without_egress.*.id[count.index]
  route_table_id = aws_route_table.sagemaker[0].id
}

resource "aws_cloudwatch_log_group" "vpc_sagemaker_flow_log" {
  count             = var.sagemaker_on ? 1 : 0
  name              = "${var.prefix}-vpc-sagemaker-flow-log"
  retention_in_days = "3653"
}

resource "aws_iam_role" "vpc_sagemaker_flow_log" {
  count              = var.sagemaker_on ? 1 : 0
  name               = "${var.prefix}-vpc-sagemaker-flow-log"
  assume_role_policy = data.aws_iam_policy_document.vpc_sagemaker_flow_log_vpc_flow_logs_assume_role[0].json
}

data "aws_iam_policy_document" "vpc_sagemaker_flow_log_vpc_flow_logs_assume_role" {
  count = var.sagemaker_on ? 1 : 0
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

resource "aws_flow_log" "sagemaker" {
  count           = var.sagemaker_on ? 1 : 0
  log_destination = aws_cloudwatch_log_group.vpc_sagemaker_flow_log[0].arn
  iam_role_arn    = aws_iam_role.vpc_sagemaker_flow_log[0].arn
  vpc_id          = aws_vpc.sagemaker[0].id
  traffic_type    = "ALL"
}
