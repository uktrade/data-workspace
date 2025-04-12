resource "aws_acm_certificate" "arango" {
  count       = var.arango_on ? 1 : 0
  domain_name = "arango.${var.admin_domain}"

  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "arango" {
  count           = var.arango_on ? 1 : 0
  certificate_arn = aws_acm_certificate.arango[0].arn
}
