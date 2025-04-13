resource "aws_security_group" "quicksight" {
  name        = var.quicksight_security_group_name
  description = var.quicksight_security_group_description
  vpc_id      = aws_vpc.datasets.id

  tags = {
    Name = "${var.quicksight_security_group_name}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "quicksight_ingress_all_from_datasets_db" {
  description = "ingress-all-from-datasets-db"

  security_group_id        = aws_security_group.quicksight.id
  source_security_group_id = aws_security_group.datasets.id

  type      = "ingress"
  from_port = "0"
  to_port   = "65535"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "quicksight_egress_postgres_to_datasets_db" {
  description = "egress-postgres-to-datasets-db"

  security_group_id        = aws_security_group.quicksight.id
  source_security_group_id = aws_security_group.datasets.id

  type      = "egress"
  from_port = aws_rds_cluster_instance.datasets.port
  to_port   = aws_rds_cluster_instance.datasets.port
  protocol  = "tcp"
}

resource "aws_security_group_rule" "datasets_db_ingress_all_from_quicksight" {
  description = "ingress-all-from-quicksight"

  security_group_id        = aws_security_group.datasets.id
  source_security_group_id = aws_security_group.quicksight.id

  type      = "ingress"
  from_port = "0"
  to_port   = "65535"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "datasets_db_egress_all_to_quicksight" {
  description = "egress-all-to-quicksight"

  security_group_id        = aws_security_group.datasets.id
  source_security_group_id = aws_security_group.quicksight.id

  type      = "egress"
  from_port = "0"
  to_port   = "65535"
  protocol  = "tcp"
}
