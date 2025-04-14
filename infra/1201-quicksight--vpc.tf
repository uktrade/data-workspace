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
