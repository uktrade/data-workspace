resource "aws_acm_certificate" "healthcheck" {
  domain_name       = var.healthcheck_domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "healthcheck" {
  certificate_arn = aws_acm_certificate.healthcheck.arn
}
