resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.prefix}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# DHCP options define DNS settings for the VPC and should stay with aws_vpc.main for clarity and tight coupling.
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

# Public subnets are part of the main VPC core networking and should be grouped with aws_vpc.main.
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

resource "aws_flow_log" "main" {
  log_destination = aws_cloudwatch_log_group.vpc_main_flow_log.arn
  iam_role_arn    = aws_iam_role.vpc_main_flow_log.arn
  vpc_id          = aws_vpc.main.id
  traffic_type    = "ALL"
}