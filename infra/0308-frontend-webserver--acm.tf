resource "aws_acm_certificate" "admin" {
  domain_name               = var.admin_domain
  subject_alternative_names = ["*.${var.admin_domain}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "admin" {
  certificate_arn = aws_acm_certificate.admin.arn
}
