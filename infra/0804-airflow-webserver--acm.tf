resource "aws_acm_certificate" "airflow_webserver" {
  count             = var.airflow_on ? 1 : 0
  domain_name       = aws_route53_record.airflow_webserver[count.index].name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "airflow_webserver" {
  count           = var.airflow_on ? 1 : 0
  certificate_arn = aws_acm_certificate.airflow_webserver[count.index].arn
}
