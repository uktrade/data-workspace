resource "aws_vpc" "matchbox" {
  count = var.matchbox_on ? 1 : 0

  cidr_block = var.vpc_matchbox_cidr

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.prefix}-matchbox"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_subnet" "matchbox_private" {
  count = var.matchbox_on ? length(var.aws_availability_zones) : 0

  vpc_id     = aws_vpc.matchbox[0].id
  cidr_block = cidrsubnet(aws_vpc.matchbox[0].cidr_block, var.vpc_matchbox_subnets_num_bits, count.index)

  availability_zone = var.aws_availability_zones[count.index]

  tags = {
    Name = "${var.prefix}-private-matchbox-${var.aws_availability_zones_short[count.index]}"
  }
}

resource "aws_vpc_peering_connection" "matchbox_to_notebooks" {
  count       = var.matchbox_on ? 1 : 0
  peer_vpc_id = aws_vpc.notebooks.id
  vpc_id      = aws_vpc.matchbox[0].id
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

resource "aws_route_table" "matchbox" {
  count  = var.matchbox_on ? 1 : 0
  vpc_id = aws_vpc.matchbox[0].id
  tags = {
    Name = "${var.prefix}-matchbox-private"
  }
}

resource "aws_route_table_association" "matchbox_private" {
  count          = var.matchbox_on ? length(var.aws_availability_zones) : 0
  subnet_id      = aws_subnet.matchbox_private.*.id[count.index]
  route_table_id = aws_route_table.matchbox[0].id
}

resource "aws_route" "pcx_matchbox_to_notebooks" {
  count                     = var.matchbox_on ? 1 : 0
  route_table_id            = aws_route_table.matchbox[0].id
  destination_cidr_block    = aws_vpc.notebooks.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.matchbox_to_notebooks[0].id
}

resource "aws_route" "matchbox_private_nat_gateway_ipv4" {
  count                  = var.matchbox_on ? 1 : 0
  route_table_id         = aws_route_table.matchbox[0].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.matchbox[0].id
}


resource "aws_route_table" "matchbox_public" {
  count  = var.matchbox_on ? 1 : 0
  vpc_id = aws_vpc.matchbox[0].id
  tags = {
    Name = "${var.prefix}-matchbox-public"
  }
}

resource "aws_subnet" "matchbox_public" {
  count = var.matchbox_on ? length(var.aws_availability_zones) : 0

  vpc_id     = aws_vpc.matchbox[0].id
  cidr_block = cidrsubnet(aws_vpc.matchbox[0].cidr_block, var.vpc_matchbox_subnets_num_bits, length(var.aws_availability_zones) + count.index)

  availability_zone = var.aws_availability_zones[count.index]

  tags = {
    Name = "${var.prefix}-public-matchbox-${var.aws_availability_zones_short[count.index]}"
  }
}

resource "aws_route_table_association" "matchbox_public" {
  count          = var.matchbox_on ? length(var.aws_availability_zones) : 0
  subnet_id      = aws_subnet.matchbox_public[count.index].id
  route_table_id = aws_route_table.matchbox_public[0].id
}


resource "aws_internet_gateway" "matchbox" {
  count  = var.matchbox_on ? 1 : 0
  vpc_id = aws_vpc.matchbox[0].id

  tags = {
    Name = "${var.prefix}-matchbox"
  }
}

resource "aws_route" "matchbox_public_internet_gateway" {
  count                  = var.matchbox_on ? 1 : 0
  route_table_id         = aws_route_table.matchbox_public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.matchbox[0].id
}

resource "aws_nat_gateway" "matchbox" {
  count         = var.matchbox_on ? 1 : 0
  allocation_id = aws_eip.matchbox[0].id
  subnet_id     = aws_subnet.matchbox_public[0].id

  tags = {
    Name = "${var.prefix}-matchbox"
  }
}

resource "aws_eip" "matchbox" {
  count = var.matchbox_on ? 1 : 0
  vpc   = true
}

resource "aws_route" "private_without_egress_to_matchbox" {
  count = var.matchbox_on ? length(var.aws_availability_zones) : 0

  route_table_id            = aws_route_table.private_without_egress.id
  destination_cidr_block    = aws_subnet.matchbox_private.*.cidr_block[count.index]
  vpc_peering_connection_id = aws_vpc_peering_connection.matchbox_to_notebooks[0].id
}
