resource "aws_route53_record" "mlflow_internal" {
  count    = var.mlflow_on ? length(var.mlflow_instances) : 0
  provider = aws.route53
  zone_id  = data.aws_route53_zone.aws_route53_zone.zone_id
  name     = "mlflow--${var.mlflow_instances_long[count.index]}--internal.${var.admin_domain}"
  type     = "A"
  ttl      = "60"
  records  = [aws_lb.mlflow.*.subnet_mapping[count.index].*.private_ipv4_address[0]]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "mlflow_data_flow" {
  count    = var.mlflow_on ? length(var.mlflow_instances) : 0
  provider = aws.route53
  zone_id  = data.aws_route53_zone.aws_route53_zone.zone_id
  name     = "mlflow--${var.mlflow_instances_long[count.index]}--data-flow.${var.admin_domain}"
  type     = "A"
  ttl      = "60"
  records  = [aws_lb.mlflow_dataflow.*.subnet_mapping[count.index].*.private_ipv4_address[0]]

  lifecycle {
    create_before_destroy = true
  }
}
