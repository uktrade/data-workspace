resource "aws_route53_record" "healthcheck" {
  provider = aws.route53
  zone_id  = data.aws_route53_zone.aws_route53_zone.zone_id
  name     = aws_acm_certificate.healthcheck.domain_name
  type     = "A"

  alias {
    name                   = aws_alb.healthcheck.dns_name
    zone_id                = aws_alb.healthcheck.zone_id
    evaluate_target_health = false
  }

  lifecycle {
    create_before_destroy = true
  }
}
