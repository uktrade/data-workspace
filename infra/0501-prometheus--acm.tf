resource "aws_acm_certificate" "prometheus" {
  domain_name       = var.prometheus_domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "prometheus" {
  certificate_arn = aws_acm_certificate.prometheus.arn
}
