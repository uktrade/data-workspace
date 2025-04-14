resource "aws_vpc_endpoint" "airflow_resource_endpoints" {
  count = length(var.airflow_resource_endpoints)

  vpc_endpoint_type          = "Resource"
  resource_configuration_arn = var.airflow_resource_endpoints[count.index].arn
  vpc_id                     = aws_vpc.main.id
  subnet_ids                 = aws_subnet.private_with_egress[*].id

  private_dns_enabled = true
  security_group_ids  = [aws_security_group.airflow_resource_endpoints[count.index].id]
}
