resource "aws_acm_certificate" "gitlab" {
  count             = var.gitlab_on ? 1 : 0
  domain_name       = var.gitlab_domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "gitlab" {
  count           = var.gitlab_on ? 1 : 0
  certificate_arn = aws_acm_certificate.gitlab[count.index].arn
}
