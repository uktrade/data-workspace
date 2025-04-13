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
