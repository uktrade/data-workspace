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

resource "aws_vpc_endpoint" "main_s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.aws_region.name}.s3"
  vpc_endpoint_type = "Gateway"
}

resource "aws_vpc_endpoint_route_table_association" "main_s3" {
  vpc_endpoint_id = aws_vpc_endpoint.main_s3.id
  route_table_id  = aws_route_table.private_with_egress.id
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

resource "aws_route" "private_with_egress_nat_gateway_ipv4" {
  route_table_id         = aws_route_table.private_with_egress.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main.id
}

resource "aws_eip" "nat_gateway" {
  vpc = true
}
