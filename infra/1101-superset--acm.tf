resource "aws_acm_certificate" "superset_internal" {
  count             = var.superset_on ? 1 : 0
  domain_name       = aws_route53_record.superset_internal[count.index].name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "superset_internal" {
  count           = var.superset_on ? 1 : 0
  certificate_arn = aws_acm_certificate.superset_internal[count.index].arn
}
