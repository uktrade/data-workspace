resource "aws_security_group" "notebooks_endpoints" {
  name        = "${var.prefix}-notebooks-endpoints"
  description = "${var.prefix}-notebooks-endpoints"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.prefix}-notebooks-endpoints"
  }

  lifecycle {
    create_before_destroy = true
    # prevent_destroy = false
  }
}

resource "aws_security_group_rule" "notebooks_endpoint_ingress_sagemaker" {
  description       = "endpoint-ingress-from-datasets-vpc"
  security_group_id = aws_security_group.notebooks_endpoints.id
  cidr_blocks       = var.cidr_blocks
  type              = "ingress"
  from_port         = "0"
  to_port           = "65535"
  protocol          = "tcp"
}

resource "aws_security_group_rule" "notebooks_endpoint_egress_sagemaker" {
  description       = "endpoint-egress-from-datasets-vpc"
  security_group_id = aws_security_group.notebooks_endpoints.id
  cidr_blocks       = var.cidr_blocks
  type              = "egress"
  from_port         = "0"
  to_port           = "65535"
  protocol          = "tcp"
}
