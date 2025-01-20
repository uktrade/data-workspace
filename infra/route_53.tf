data "aws_route53_zone" "aws_route53_zone" {
  # provider = "aws.route53"
  name = var.aws_route53_zone
}

resource "aws_route53_record" "admin" {
  # provider = "aws.route53"
  zone_id = data.aws_route53_zone.aws_route53_zone.zone_id
  name    = var.admin_domain
  type    = "A"

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
  # provider = "aws.route53"
  zone_id = data.aws_route53_zone.aws_route53_zone.zone_id
  name    = "*.${var.admin_domain}"
  type    = "A"

  alias {
    name                   = aws_alb.admin.dns_name
    zone_id                = aws_alb.admin.zone_id
    evaluate_target_health = false
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate" "admin" {
  domain_name               = aws_route53_record.admin.name
  subject_alternative_names = ["*.${aws_route53_record.admin.name}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "admin" {
  certificate_arn = aws_acm_certificate.admin.arn
}

resource "aws_route53_record" "healthcheck" {
  # provider = "aws.route53"
  zone_id = data.aws_route53_zone.aws_route53_zone.zone_id
  name    = var.healthcheck_domain
  type    = "A"

  alias {
    name                   = aws_alb.healthcheck.dns_name
    zone_id                = aws_alb.healthcheck.zone_id
    evaluate_target_health = false
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate" "healthcheck" {
  domain_name       = aws_route53_record.healthcheck.name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "healthcheck" {
  certificate_arn = aws_acm_certificate.healthcheck.arn
}

resource "aws_route53_record" "prometheus" {
  # provider = "aws.route53"
  zone_id = data.aws_route53_zone.aws_route53_zone.zone_id
  name    = var.prometheus_domain
  type    = "A"

  alias {
    name                   = aws_alb.prometheus.dns_name
    zone_id                = aws_alb.prometheus.zone_id
    evaluate_target_health = false
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate" "prometheus" {
  domain_name       = aws_route53_record.prometheus.name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "prometheus" {
  certificate_arn = aws_acm_certificate.prometheus.arn
}

resource "aws_route53_record" "gitlab" {
  count = var.gitlab_on ? 1 : 0
  # provider = "aws.route53"
  zone_id = data.aws_route53_zone.aws_route53_zone.zone_id
  name    = var.gitlab_domain
  type    = "A"

  alias {
    name                   = aws_lb.gitlab[count.index].dns_name
    zone_id                = aws_lb.gitlab[count.index].zone_id
    evaluate_target_health = false
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "superset_internal" {
  count = var.superset_on ? 1 : 0
  # provider = "aws.route53"
  zone_id = data.aws_route53_zone.aws_route53_zone.zone_id
  name    = var.superset_internal_domain
  type    = "A"

  alias {
    name                   = aws_lb.superset[count.index].dns_name
    zone_id                = aws_lb.superset[count.index].zone_id
    evaluate_target_health = false
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "mlflow_internal" {
  count = var.mlflow_on ? length(var.mlflow_instances) : 0
  # provider = "aws.route53"
  zone_id = data.aws_route53_zone.aws_route53_zone.zone_id
  name    = "mlflow--${var.mlflow_instances_long[count.index]}--internal.${var.admin_domain}"
  type    = "A"
  ttl     = "60"
  records = [aws_lb.mlflow.*.subnet_mapping[count.index].*.private_ipv4_address[0]]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "mlflow_data_flow" {
  count = var.mlflow_on ? length(var.mlflow_instances) : 0
  # provider = "aws.route53"
  zone_id = data.aws_route53_zone.aws_route53_zone.zone_id
  name    = "mlflow--${var.mlflow_instances_long[count.index]}--data-flow.${var.admin_domain}"
  type    = "A"
  ttl     = "60"
  records = [aws_lb.mlflow_dataflow.*.subnet_mapping[count.index].*.private_ipv4_address[0]]

  lifecycle {
    create_before_destroy = true
  }
}

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

resource "aws_route53_record" "arango" {
  count = var.arango_on ? 1 : 0
  # provider = "aws.route53"
  zone_id = data.aws_route53_zone.aws_route53_zone.zone_id
  name    = "arango.${var.admin_domain}"
  type    = "A"

  alias {
    name                   = aws_lb.arango[0].dns_name
    zone_id                = aws_lb.arango[0].zone_id
    evaluate_target_health = false
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "airflow_webserver" {
  count = var.airflow_on ? 1 : 0
  # provider = aws.route53
  zone_id = data.aws_route53_zone.aws_route53_zone.zone_id
  name    = var.airflow_domain
  type    = "A"

  alias {
    name                   = aws_lb.airflow_webserver[count.index].dns_name
    zone_id                = aws_lb.airflow_webserver[count.index].zone_id
    evaluate_target_health = false
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate" "arango" {
  count       = var.arango_on ? 1 : 0
  domain_name = aws_route53_record.arango[0].name

  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate" "airflow_webserver" {
  count             = var.airflow_on ? 1 : 0
  domain_name       = aws_route53_record.airflow_webserver[count.index].name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "arango" {
  count           = var.arango_on ? 1 : 0
  certificate_arn = aws_acm_certificate.arango[0].arn
}

resource "aws_acm_certificate_validation" "airflow_webserver" {
  count           = var.airflow_on ? 1 : 0
  certificate_arn = aws_acm_certificate.airflow_webserver[count.index].arn
}

# resource "aws_route53_record" "jupyterhub" {
#   zone_id = "${data.aws_route53_zone.aws_route53_zone.zone_id}"
#   name    = "${var.jupyterhub_domain}."
#   type    = "A"

#   alias {
#     name                   = "${aws_alb.jupyterhub.dns_name}"
#     zone_id                = "${aws_alb.jupyterhub.zone_id}"
#     evaluate_target_health = false
#   }

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# resource "aws_acm_certificate" "jupyterhub" {
#   domain_name       = "${aws_route53_record.jupyterhub.name}"
#   validation_method = "DNS"

#   # subject_alternative_names = [
#   #   "${var.jupyterhub_secondary_domain}",
#   # ]

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# resource "aws_acm_certificate_validation" "jupyterhub" {
#   certificate_arn = "${aws_acm_certificate.jupyterhub.arn}"
# }

# hosted zone to create a private DNS record for the Sagemaker endpoints
# avoids turning on dns support in notebooks VPC 

resource "aws_route53_zone" "sagemaker_runtime_hosted_zone" {
  name = "runtime.sagemaker.eu-west-2.amazonaws.com"
  # name = "${var.prefix}-sagemaker-runtime-hosted-zone"

  vpc {
    vpc_id = aws_vpc.notebooks.id
  }
}

# Sagemaker Runtime DNS records
data "aws_vpc_endpoint" "sagemaker_runtime" {
  vpc_id       = aws_vpc.sagemaker.id
  service_name = "com.amazonaws.eu-west-2.sagemaker.runtime"
}

data "aws_network_interface" "sagemaker_runtime_network_interface" {
  id       = tolist(data.aws_vpc_endpoint.sagemaker_runtime.network_interface_ids)[0]
}

resource "aws_route53_record" "sagemaker_runtime_DNS_record" {
  # for_each = {for idx, val in tolist(data.aws_vpc_endpoint.sagemaker_runtime.network_interface_ids) : idx => val if idx == 0}
  zone_id  = aws_route53_zone.sagemaker_runtime_hosted_zone.zone_id
  name     = "runtime.sagemaker.${data.aws_region.aws_region.name}.amazonaws.com"
  type     = "A"
  ttl      = 300
  records  = [data.aws_network_interface.sagemaker_runtime_network_interface.private_ip]
}

resource "aws_route53_zone" "sagemaker_api_hosted_zone" {
  name = "${var.prefix}-sagemaker-api-hosted-zone"

  vpc {
    vpc_id = aws_vpc.notebooks.id
  }
}

# SageMaker API DNS records
data "aws_vpc_endpoint" "sagemaker_api" {
  vpc_id       = aws_vpc.sagemaker.id
  service_name = "com.amazonaws.eu-west-2.sagemaker.api"
}

data "aws_network_interface" "sagemaker_api_network_interface" {
  id = tolist(data.aws_vpc_endpoint.sagemaker_api.network_interface_ids)[0]
}

resource "aws_route53_record" "sagemaker_api_DNS_record" {
  # for_each = {for idx, val in tolist(data.aws_vpc_endpoint.sagemaker_api.network_interface_ids) : idx => val if idx == 0}
  zone_id  = aws_route53_zone.sagemaker_api_hosted_zone.zone_id
  name     = "api.sagemaker.${data.aws_region.aws_region.name}.amazonaws.com"
  type     = "A"
  ttl      = 60
  records  = [data.aws_network_interface.sagemaker_api_network_interface.private_ip]
}