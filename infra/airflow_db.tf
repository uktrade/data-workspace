resource "aws_db_subnet_group" "airflow" {
  count      = var.airflow_on ? 1 : 0
  name       = "${var.prefix}-airflow"
  subnet_ids = aws_subnet.private_with_egress.*.id

  tags = {
    Name = "${var.prefix}-airflow"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "random_string" "aws_db_instance_airflow_password" {
  length  = 99
  special = false
}
