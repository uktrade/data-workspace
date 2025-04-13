resource "aws_route53_record" "admin" {
  provider = aws.route53
  zone_id  = data.aws_route53_zone.aws_route53_zone.zone_id
  name     = aws_acm_certificate.admin.domain_name
  type     = "A"

  alias {
    name                   = aws_alb.admin.dns_name
    zone_id                = aws_alb.admin.zone_id
    evaluate_target_health = false
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "applications" {
  provider = aws.route53
  zone_id  = data.aws_route53_zone.aws_route53_zone.zone_id
  name     = "*.${aws_acm_certificate.admin.domain_name}"
  type     = "A"

  alias {
    name                   = aws_alb.admin.dns_name
    zone_id                = aws_alb.admin.zone_id
    evaluate_target_health = false
  }

  lifecycle {
    create_before_destroy = true
  }
}
