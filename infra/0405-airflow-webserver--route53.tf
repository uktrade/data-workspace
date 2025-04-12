resource "aws_route53_record" "airflow_webserver" {
  count    = var.airflow_on ? 1 : 0
  provider = aws.route53
  zone_id  = data.aws_route53_zone.aws_route53_zone.zone_id
  name     = var.airflow_domain
  type     = "A"

  alias {
    name                   = aws_lb.airflow_webserver[count.index].dns_name
    zone_id                = aws_lb.airflow_webserver[count.index].zone_id
    evaluate_target_health = false
  }

  lifecycle {
    create_before_destroy = true
  }
}
