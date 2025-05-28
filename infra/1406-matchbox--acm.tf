resource "aws_acm_certificate" "matchbox" {
  count             = var.matchbox_on ? 1 : 0
  domain_name       = "matchbox.${var.admin_domain}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "matchbox" {
  count           = var.matchbox_on ? 1 : 0
  certificate_arn = aws_acm_certificate.matchbox[count.index].arn
}