resource "aws_route53_record" "superset_internal" {
  count    = var.superset_on ? 1 : 0
  provider = aws.route53
  zone_id  = data.aws_route53_zone.aws_route53_zone.zone_id
  name     = var.superset_internal_domain
  type     = "A"

  alias {
    name                   = aws_lb.superset[count.index].dns_name
    zone_id                = aws_lb.superset[count.index].zone_id
    evaluate_target_health = false
  }

  lifecycle {
    create_before_destroy = true
  }
}
