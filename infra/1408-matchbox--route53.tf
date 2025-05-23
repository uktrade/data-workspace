resource "aws_route53_record" "matchbox" {
  count    = var.matchbox_on ? 1 : 0
  provider = aws.route53
  zone_id  = data.aws_route53_zone.aws_route53_zone.zone_id
  name     = aws_acm_certificate.matchbox[0].domain_name
  type     = "A"

  alias {
    name                   = aws_lb.matchbox[0].dns_name
    zone_id                = aws_lb.matchbox[0].zone_id
    evaluate_target_health = false
  }

  lifecycle {
    create_before_destroy = true
  }
}