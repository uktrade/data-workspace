resource "aws_route53_record" "gitlab" {
  count    = var.gitlab_on ? 1 : 0
  provider = aws.route53
  zone_id  = data.aws_route53_zone.aws_route53_zone.zone_id
  name     = aws_acm_certificate.gitlab[0].domain_name
  type     = "A"

  alias {
    name                   = aws_lb.gitlab[count.index].dns_name
    zone_id                = aws_lb.gitlab[count.index].zone_id
    evaluate_target_health = false
  }

  lifecycle {
    create_before_destroy = true
  }
}
