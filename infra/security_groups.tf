###################################################################################################
#
# IMPORTANT
#
# This file is "legacy". Unless an urgent change is needed, do not change this file other than to
# remove security groups or rules.
#
# Instead:
#
# 1. Place definitions of security groups close to the definition of the resources that are
#    assigned them. In most cases the same file as the resource is defined is appropriate. In the
#    rare case that there is no resource, a "--sg.tf" file should be created for this.
#
# 2. Place security groups rules next to the security group definition of the _client_ side of
#    the relationship, i.e. the one that needs the egress rule. In the rare case that there is
#    no client security group, for example if exposing a server to a CIDR, then a separate file
#    ending in "--sg.tf" file should be made for these rules (possibly via a prefix list).
#
# 3. And ideally use ./module/security_group_client_server_connections to create the rules.
#
###################################################################################################


resource "aws_security_group" "dns_rewrite_proxy" {
  name        = "${var.prefix}-dns-rewrite-proxy"
  description = "${var.prefix}-dns-rewrite-proxy"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.prefix}-dns-rewrite-proxy"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "dns_rewrite_proxy_ingress_healthcheck" {
  description       = "ingress-private-with-egress-healthcheck"
  type              = "ingress"
  from_port         = "8888"
  to_port           = "8888"
  protocol          = "tcp"
  cidr_blocks       = ["${aws_subnet.private_with_egress.*.cidr_block[0]}"]
  security_group_id = aws_security_group.dns_rewrite_proxy.id
}

resource "aws_security_group_rule" "dns_rewrite_proxy_ingress_udp" {
  count = length(aws_subnet.private_without_egress)

  description       = "ingress-private-without-egress-udp-${var.aws_availability_zones_short[count.index]}"
  type              = "ingress"
  from_port         = "53"
  to_port           = "53"
  protocol          = "udp"
  cidr_blocks       = ["${aws_subnet.private_without_egress[count.index].cidr_block}"]
  security_group_id = aws_security_group.dns_rewrite_proxy.id
}


resource "aws_security_group_rule" "dns_rewrite_proxy_egress_https" {
  description = "egress-dns-tcp"

  security_group_id = aws_security_group.dns_rewrite_proxy.id
  cidr_blocks       = ["0.0.0.0/0"]

  type      = "egress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}


resource "aws_security_group" "sentryproxy_service" {
  name        = "${var.prefix}-sentryproxy"
  description = "${var.prefix}-sentryproxy"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.prefix}-sentryproxy"
  }

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_security_group" "admin_alb" {
  name        = "${var.prefix}-admin-alb"
  description = "${var.prefix}-admin-alb"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.prefix}-admin-alb"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "admin_alb_ingress_https_from_whitelist" {
  description = "ingress-https-from-whitelist"

  security_group_id = aws_security_group.admin_alb.id
  cidr_blocks       = concat("${var.ip_whitelist}", ["${aws_eip.nat_gateway.public_ip}/32"])

  type      = "ingress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "admin_alb_ingress_icmp_host_unreachable_for_mtu_discovery_from_whitelist" {
  description = "ingress-icmp-host-unreachable-for-mtu-discovery-from-whitelist"

  security_group_id = aws_security_group.admin_alb.id
  cidr_blocks       = var.ip_whitelist

  type      = "ingress"
  from_port = 3
  to_port   = 0
  protocol  = "icmp"
}

resource "aws_security_group_rule" "admin_alb_egress_https_to_admin_service" {
  description = "egress-https-to-admin-service"

  security_group_id        = aws_security_group.admin_alb.id
  source_security_group_id = aws_security_group.admin_service.id

  type      = "egress"
  from_port = local.admin_container_port
  to_port   = local.admin_container_port
  protocol  = "tcp"
}

resource "aws_security_group_rule" "admin_alb_egress_https_to_cloudwatch" {
  description = "egress-https-to-cloudwatch"

  security_group_id        = aws_security_group.admin_alb.id
  source_security_group_id = aws_security_group.cloudwatch.id

  type      = "egress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

resource "aws_security_group" "admin_redis" {
  name        = "${var.prefix}-admin-redis"
  description = "${var.prefix}-admin-redis"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.prefix}-admin-redis"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "admin_redis_egress_https_to_cloudwatch" {
  description = "egress-https-to-cloudwatch"

  security_group_id        = aws_security_group.admin_redis.id
  source_security_group_id = aws_security_group.cloudwatch.id

  type      = "egress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "admin_redis_ingress_from_admin_service" {
  description = "ingress-redis-from-admin-service"

  security_group_id        = aws_security_group.admin_redis.id
  source_security_group_id = aws_security_group.admin_service.id

  type      = "ingress"
  from_port = "6379"
  to_port   = "6379"
  protocol  = "tcp"
}

resource "aws_security_group" "admin_service" {
  name        = "${var.prefix}-admin-service"
  description = "${var.prefix}-admin-service"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.prefix}-admin-service"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "admin_service_egress_http_to_superset_lb" {
  count       = var.gitlab_on ? 1 : 0
  description = "egress-http-to-gitlab-service"

  security_group_id        = aws_security_group.admin_service.id
  source_security_group_id = aws_security_group.superset_lb.id

  type      = "egress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "admin_service_egress_http_to_flower_lb" {
  description = "egress-http-to-flower-lb"

  security_group_id        = aws_security_group.admin_service.id
  source_security_group_id = aws_security_group.flower_lb.id

  type      = "egress"
  from_port = "80"
  to_port   = "80"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "admin_service_egress_http_to_mlflow" {
  count       = var.mlflow_on ? length(var.mlflow_instances) : 0
  description = "egress-http-to-mlflow-lb"

  security_group_id = aws_security_group.admin_service.id
  cidr_blocks       = ["${aws_lb.mlflow.*.subnet_mapping[count.index].*.private_ipv4_address[0]}/32"]

  type      = "egress"
  from_port = local.mlflow_port
  to_port   = local.mlflow_port
  protocol  = "tcp"
}

resource "aws_security_group_rule" "admin_service_egress_http_to_gitlab_service" {
  count       = var.gitlab_on ? 1 : 0
  description = "egress-http-to-gitlab-service"

  security_group_id        = aws_security_group.admin_service.id
  source_security_group_id = aws_security_group.gitlab_service[count.index].id

  type      = "egress"
  from_port = "80"
  to_port   = "80"
  protocol  = "tcp"
}


resource "aws_security_group_rule" "admin_service_egress_https_to_cloudwatch" {
  description = "egress-https-to-cloudwatch"

  security_group_id        = aws_security_group.admin_service.id
  source_security_group_id = aws_security_group.cloudwatch.id

  type      = "egress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "admin_service_egress_to_admin_service" {
  description = "egress-redis-to-admin-redis"

  security_group_id        = aws_security_group.admin_service.id
  source_security_group_id = aws_security_group.admin_redis.id

  type      = "egress"
  from_port = "6379"
  to_port   = "6379"
  protocol  = "tcp"
}


resource "aws_security_group_rule" "admin_service_ingress_https_from_admin_alb" {
  description = "ingress-https-from-admin-alb"

  security_group_id        = aws_security_group.admin_service.id
  source_security_group_id = aws_security_group.admin_alb.id

  type      = "ingress"
  from_port = local.admin_container_port
  to_port   = local.admin_container_port
  protocol  = "tcp"
}

resource "aws_security_group_rule" "admin_service_egress_https_to_everywhere" {
  description = "egress-https-to-everywhere"

  security_group_id = aws_security_group.admin_service.id
  cidr_blocks       = ["0.0.0.0/0"]

  type      = "egress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "admin_service_egress_http_airflow_webserver" {
  description = "egress-http-to-airflow-webserver"

  security_group_id        = aws_security_group.admin_service.id
  source_security_group_id = aws_security_group.airflow_webserver.id

  type      = "egress"
  from_port = "8080"
  to_port   = "8080"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "admin_service_egress_http_to_notebooks" {
  description = "egress-https-to-everywhere"

  security_group_id        = aws_security_group.admin_service.id
  source_security_group_id = aws_security_group.notebooks.id

  type      = "egress"
  from_port = local.notebook_container_port
  to_port   = local.notebook_container_port
  protocol  = "tcp"
}

resource "aws_security_group_rule" "admin_service_egress_http_dev_to_notebooks" {
  description = "egress-http-dev-to-notebooks"

  security_group_id        = aws_security_group.admin_service.id
  source_security_group_id = aws_security_group.notebooks.id

  type      = "egress"
  from_port = local.notebook_container_port_dev
  to_port   = local.notebook_container_port_dev
  protocol  = "tcp"
}

resource "aws_security_group_rule" "admin_service_egress_postgres_to_admin_db" {
  description = "egress-postgres-to-admin-db"

  security_group_id        = aws_security_group.admin_service.id
  source_security_group_id = aws_security_group.admin_db.id

  type      = "egress"
  from_port = aws_db_instance.admin.port
  to_port   = aws_db_instance.admin.port
  protocol  = "tcp"
}

resource "aws_security_group_rule" "admin_service_egress_arango_to_aranglo_lb" {
  count       = var.arango_on ? 1 : 0
  description = "egress-arango-to-arango-lb"

  security_group_id        = aws_security_group.admin_service.id
  source_security_group_id = aws_security_group.arango_lb[0].id

  type      = "egress"
  from_port = "8529"
  to_port   = "8529"
  protocol  = "tcp"
}

resource "aws_security_group" "admin_db" {
  name        = "${var.prefix}-admin-db"
  description = "${var.prefix}-admin-db"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.prefix}-admin-db"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "admin_db_ingress_postgres_from_admin_service" {
  description = "ingress-postgres-from-admin-service"

  security_group_id        = aws_security_group.admin_db.id
  source_security_group_id = aws_security_group.admin_service.id

  type      = "ingress"
  from_port = aws_db_instance.admin.port
  to_port   = aws_db_instance.admin.port
  protocol  = "tcp"
}

resource "aws_security_group_rule" "notebooks_ingress_https_from_admin" {
  description = "ingress-https-from-jupytehub"

  security_group_id        = aws_security_group.notebooks.id
  source_security_group_id = aws_security_group.admin_service.id

  type      = "ingress"
  from_port = local.notebook_container_port
  to_port   = local.notebook_container_port
  protocol  = "tcp"
}

resource "aws_security_group_rule" "notebooks_ingress_http_dev_from_admin" {
  description = "ingress-http-dev-from-jupytehub"

  security_group_id        = aws_security_group.notebooks.id
  source_security_group_id = aws_security_group.admin_service.id

  type      = "ingress"
  from_port = local.notebook_container_port_dev
  to_port   = local.notebook_container_port_dev
  protocol  = "tcp"
}

resource "aws_security_group_rule" "notebooks_ingress_http_from_prometheus" {
  description = "ingress-https-from-prometheus-service"

  security_group_id        = aws_security_group.notebooks.id
  source_security_group_id = aws_security_group.prometheus_service.id

  type      = "ingress"
  from_port = local.notebook_container_port + 1
  to_port   = local.notebook_container_port + 1
  protocol  = "tcp"
}


#######################

resource "aws_security_group" "cloudwatch" {
  name        = "${var.prefix}-cloudwatch"
  description = "${var.prefix}-cloudwatch"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.prefix}-cloudwatch"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "ecr_dkr" {
  name        = "${var.prefix}-ecr-dkr"
  description = "${var.prefix}-ecr-dkr"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.prefix}-ecr-dkr"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "ecr_api" {
  name        = "${var.prefix}-ecr-api"
  description = "${var.prefix}-ecr-api"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.prefix}-ecr-api"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "ecr_api_ingress_https_from_tools_codebuild" {
  count       = length(local.tool_builds)
  description = "ingress-https-from-codebuild"

  security_group_id        = aws_security_group.ecr_api.id
  source_security_group_id = aws_security_group.tools_codebuild[count.index].id

  type      = "ingress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "ecr_api_ingress_https_from_dns_rewrite_proxy" {
  description = "ingress-https-from-dns-rewrite-proxy"

  security_group_id        = aws_security_group.ecr_api.id
  source_security_group_id = aws_security_group.dns_rewrite_proxy.id

  type      = "ingress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "ecr_api_ingress_https_from_prometheus" {
  description = "ingress-https-from-prometheus-service"

  security_group_id        = aws_security_group.ecr_api.id
  source_security_group_id = aws_security_group.prometheus_service.id

  type      = "ingress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "ecr_api_ingress_https_from_sentryproxy" {
  description = "ingress-https-from-sentryproxy-service"

  security_group_id        = aws_security_group.ecr_api.id
  source_security_group_id = aws_security_group.sentryproxy_service.id

  type      = "ingress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "ecr_api_ingress_https_from_admin-service" {
  description = "ingress-https-from-admin-service"

  security_group_id        = aws_security_group.ecr_api.id
  source_security_group_id = aws_security_group.admin_service.id

  type      = "ingress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "ecr_api_ingress_https_from_gitlab_ec2" {
  count       = var.gitlab_on ? 1 : 0
  description = "ingress-https-from-gitlab-ec2"

  security_group_id        = aws_security_group.ecr_api.id
  source_security_group_id = aws_security_group.gitlab-ec2[count.index].id

  type      = "ingress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "ecr_api_ingress_https_from_gitlab_runner" {
  count       = var.gitlab_on ? 1 : 0
  description = "ingress-https-from-gitlab-runner"

  security_group_id        = aws_security_group.ecr_api.id
  source_security_group_id = aws_security_group.gitlab_runner[count.index].id

  type      = "ingress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "ecr_api_ingress_https_from_mirrors_sync" {
  description = "ingress-https-from-mirrors-sync"

  security_group_id        = aws_security_group.ecr_api.id
  source_security_group_id = aws_security_group.mirrors_sync.id

  type      = "ingress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}


resource "aws_security_group_rule" "ecr_api_ingress_https_from_healthcheck" {
  description = "ingress-https-from-healthcheck-service"

  security_group_id        = aws_security_group.ecr_api.id
  source_security_group_id = aws_security_group.healthcheck_service.id

  type      = "ingress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "cloudwatch_ingress_https_from_all" {
  description = "ingress-https-from-everywhere"

  security_group_id = aws_security_group.cloudwatch.id
  cidr_blocks       = ["0.0.0.0/0"]

  type      = "ingress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "ecr_dkr_ingress_https_from_all" {
  description = "ingress-https-from-everywhere"

  security_group_id = aws_security_group.ecr_dkr.id
  cidr_blocks       = ["0.0.0.0/0"]

  type      = "ingress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

resource "aws_security_group" "mirrors_sync" {
  name        = "${var.prefix}-mirrors-sync"
  description = "${var.prefix}-mirrors-sync"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.prefix}-mirrors-sync"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "mirrors_sync_egress_https_to_everywhere" {
  description = "egress-https-to-everywhere"

  security_group_id = aws_security_group.mirrors_sync.id
  cidr_blocks       = ["0.0.0.0/0"]

  type      = "egress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

resource "aws_security_group" "healthcheck_alb" {
  name        = "${var.prefix}-healthcheck-alb"
  description = "${var.prefix}-healthcheck-alb"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.prefix}-healthcheck-alb"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "healthcheck_alb_egress_https_to_cloudwatch" {
  description = "egress-https-to-cloudwatch"

  security_group_id        = aws_security_group.healthcheck_alb.id
  source_security_group_id = aws_security_group.cloudwatch.id

  type      = "egress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "healthcheck_alb_ingress_https_from_all" {
  description = "ingress-https-from-all"

  security_group_id = aws_security_group.healthcheck_alb.id
  cidr_blocks       = ["0.0.0.0/0"]

  type      = "ingress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "healthcheck_alb_egress_https_to_healthcheck_service" {
  description = "egress-https-to-healthcheck-service"

  security_group_id        = aws_security_group.healthcheck_alb.id
  source_security_group_id = aws_security_group.healthcheck_service.id

  type      = "egress"
  from_port = local.healthcheck_container_port
  to_port   = local.healthcheck_container_port
  protocol  = "tcp"
}

resource "aws_security_group" "healthcheck_service" {
  name        = "${var.prefix}-healthcheck_service"
  description = "${var.prefix}-healthcheck_service"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.prefix}-healthcheck_service"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "healthcheck_service_egress_https_to_cloudwatch" {
  description = "egress-https-to-cloudwatch"

  security_group_id        = aws_security_group.healthcheck_service.id
  source_security_group_id = aws_security_group.cloudwatch.id

  type      = "egress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "healthcheck_service_ingress_https_from_healthcheck_alb" {
  description = "ingress-https-from-healthcheck-alb"

  security_group_id        = aws_security_group.healthcheck_service.id
  source_security_group_id = aws_security_group.healthcheck_alb.id

  type      = "ingress"
  from_port = local.healthcheck_container_port
  to_port   = local.healthcheck_container_port
  protocol  = "tcp"
}

resource "aws_security_group_rule" "healthcheck_service_egress_https_to_everywhere" {
  description = "ingress-https-from-healthcheck-alb"

  security_group_id = aws_security_group.healthcheck_service.id
  cidr_blocks       = ["0.0.0.0/0"]

  type      = "egress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

resource "aws_security_group" "prometheus_alb" {
  name        = "${var.prefix}-prometheus-alb"
  description = "${var.prefix}-prometheus-alb"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.prefix}-prometheus-alb"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "prometheus_alb_egress_https_to_cloudwatch" {
  description = "egress-https-to-cloudwatch"

  security_group_id        = aws_security_group.prometheus_alb.id
  source_security_group_id = aws_security_group.cloudwatch.id

  type      = "egress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "prometheus_alb_ingress_https_from_whitelist" {
  description = "ingress-https-from-all"

  security_group_id = aws_security_group.prometheus_alb.id
  cidr_blocks       = concat("${var.prometheus_whitelist}", ["${aws_eip.nat_gateway.public_ip}/32"])

  type      = "ingress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "prometheus_alb_egress_https_to_prometheus_service" {
  description = "egress-https-to-prometheus-service"

  security_group_id        = aws_security_group.prometheus_alb.id
  source_security_group_id = aws_security_group.prometheus_service.id

  type      = "egress"
  from_port = local.prometheus_container_port
  to_port   = local.prometheus_container_port
  protocol  = "tcp"
}

resource "aws_security_group" "prometheus_service" {
  name        = "${var.prefix}-prometheus_service"
  description = "${var.prefix}-prometheus_service"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.prefix}-prometheus_service"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "prometheus_service_ingress_https_from_prometheus_alb" {
  description = "ingress-https-from-prometheus-alb"

  security_group_id        = aws_security_group.prometheus_service.id
  source_security_group_id = aws_security_group.prometheus_alb.id

  type      = "ingress"
  from_port = local.prometheus_container_port
  to_port   = local.prometheus_container_port
  protocol  = "tcp"
}

resource "aws_security_group_rule" "prometheus_service_egress_https_to_everywhere" {
  description = "egress-https-from-prometheus-service"

  security_group_id = aws_security_group.prometheus_service.id
  cidr_blocks       = ["0.0.0.0/0"]

  type      = "egress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "prometheus_service_egress_http_to_notebooks" {
  description = "egress-https-from-prometheus-service"

  security_group_id        = aws_security_group.prometheus_service.id
  source_security_group_id = aws_security_group.notebooks.id

  type      = "egress"
  from_port = local.notebook_container_port + 1
  to_port   = local.notebook_container_port + 1
  protocol  = "tcp"
}

resource "aws_security_group" "gitlab_service" {
  count       = var.gitlab_on ? 1 : 0
  name        = "${var.prefix}-gitlab-service"
  description = "${var.prefix}-gitlab-service"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.prefix}-gitlab-service"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "gitlab_service_ingress_http_from_nlb" {
  count       = var.gitlab_on ? 1 : 0
  description = "ingress-https-from-nlb"

  security_group_id = aws_security_group.gitlab_service[count.index].id
  cidr_blocks       = ["${aws_eip.gitlab[count.index].private_ip}/32"]

  type      = "ingress"
  from_port = "80"
  to_port   = "80"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "gitlab_service_ingress_http_from_whitelist" {
  count       = var.gitlab_on ? 1 : 0
  description = "ingress-http-from-whitelist"

  security_group_id = aws_security_group.gitlab_service[count.index].id
  cidr_blocks       = var.gitlab_ip_whitelist

  type      = "ingress"
  from_port = "80"
  to_port   = "80"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "gitlab_service_ingress_http_from_admin_service" {
  count       = var.gitlab_on ? 1 : 0
  description = "ingress-http-from-admin-service"

  security_group_id        = aws_security_group.gitlab_service[count.index].id
  source_security_group_id = aws_security_group.admin_service.id

  type      = "ingress"
  from_port = "80"
  to_port   = "80"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "gitlab_service_ingress_https_from_gitlab_runner" {
  count       = var.gitlab_on ? 1 : 0
  description = "ingress-https-from-gitlab-runner"

  security_group_id        = aws_security_group.gitlab_service[count.index].id
  source_security_group_id = aws_security_group.gitlab_runner[count.index].id

  type      = "ingress"
  from_port = "80"
  to_port   = "80"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "gitlab_service_ingress_ssh_from_nlb" {
  count       = var.gitlab_on ? 1 : 0
  description = "ingress-ssh-from-nlb"

  security_group_id = aws_security_group.gitlab_service[count.index].id
  cidr_blocks       = ["${aws_eip.gitlab[count.index].private_ip}/32"]

  type      = "ingress"
  from_port = "22"
  to_port   = "22"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "gitlab_service_ingress_ssh_from_whitelist" {
  count       = var.gitlab_on ? 1 : 0
  description = "ingress-http-from-whitelist"

  security_group_id = aws_security_group.gitlab_service[count.index].id
  cidr_blocks       = var.gitlab_ip_whitelist

  type      = "ingress"
  from_port = "22"
  to_port   = "22"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "gitlab_service_egress_https_to_everwhere" {
  count       = var.gitlab_on ? 1 : 0
  description = "egress-https-to-everywhere"

  security_group_id = aws_security_group.gitlab_service[count.index].id
  cidr_blocks       = ["0.0.0.0/0"]

  type      = "egress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "gitlab_service_egress_postgres_to_gitlab_db" {
  count       = var.gitlab_on ? 1 : 0
  description = "egress-postgres-to-gitlab-db"

  security_group_id        = aws_security_group.gitlab_service[count.index].id
  source_security_group_id = aws_security_group.gitlab_db[count.index].id

  type      = "egress"
  from_port = aws_rds_cluster.gitlab[count.index].port
  to_port   = aws_rds_cluster.gitlab[count.index].port
  protocol  = "tcp"
}

resource "aws_security_group_rule" "gitlab_service_egress_redis" {
  count       = var.gitlab_on ? 1 : 0
  description = "egress-redis"

  security_group_id        = aws_security_group.gitlab_service[count.index].id
  source_security_group_id = aws_security_group.gitlab_redis[count.index].id

  type      = "egress"
  from_port = "6379"
  to_port   = "6379"
  protocol  = "tcp"
}

resource "aws_security_group" "gitlab_redis" {
  count       = var.gitlab_on ? 1 : 0
  name        = "${var.prefix}-gitlab-redis"
  description = "${var.prefix}-gitlab-redis"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.prefix}-admin-gitlab"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "admin_gitlab_ingress_from_gitlab_service" {
  count       = var.gitlab_on ? 1 : 0
  description = "ingress-gitlab-from-admin-service"

  security_group_id        = aws_security_group.gitlab_redis[count.index].id
  source_security_group_id = aws_security_group.gitlab_service[count.index].id

  type      = "ingress"
  from_port = "6379"
  to_port   = "6379"
  protocol  = "tcp"
}

resource "aws_security_group" "gitlab_db" {
  count       = var.gitlab_on ? 1 : 0
  name        = "${var.prefix}-gitlab-db"
  description = "${var.prefix}-gitlab-db"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.prefix}-gitlab-db"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "gitlab_db_ingress_from_gitlab_service" {
  count       = var.gitlab_on ? 1 : 0
  description = "egress-postgres-to-gitlab-db"

  security_group_id        = aws_security_group.gitlab_db[count.index].id
  source_security_group_id = aws_security_group.gitlab_service[count.index].id

  type      = "ingress"
  from_port = aws_rds_cluster.gitlab[count.index].port
  to_port   = aws_rds_cluster.gitlab[count.index].port
  protocol  = "tcp"
}

resource "aws_security_group" "gitlab-ec2" {
  count       = var.gitlab_on ? 1 : 0
  name        = "${var.prefix}-gitlab-ec2"
  description = "${var.prefix}-gitlab-ec2"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.prefix}-gitlab-ec2"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "gitlab-ec2-egress-all" {
  count       = var.gitlab_on ? 1 : 0
  description = "egress-everything-to-everywhere"

  security_group_id = aws_security_group.gitlab-ec2[count.index].id
  cidr_blocks       = ["0.0.0.0/0"]

  type      = "egress"
  from_port = "0"
  to_port   = "65535"
  protocol  = "tcp"
}

resource "aws_security_group" "gitlab_runner" {
  count       = var.gitlab_on ? 1 : 0
  name        = "${var.prefix}-gitlab-runner"
  description = "${var.prefix}-gitlab-runner"
  vpc_id      = aws_vpc.notebooks.id

  tags = {
    Name = "${var.prefix}-gitlab-runner"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "gitlab_runner_egress_https_to_ecr_api" {
  count       = var.gitlab_on ? 1 : 0
  description = "egress-https-to-ecr-api"

  security_group_id        = aws_security_group.gitlab_runner[count.index].id
  source_security_group_id = aws_security_group.ecr_api.id

  type      = "egress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "gitlab_runner_egress_dns_udp_dns_rewrite_proxy" {
  count       = var.gitlab_on ? 1 : 0
  description = "egress-dns-udp-dns-rewrite-proxy"

  security_group_id = aws_security_group.gitlab_runner[count.index].id
  cidr_blocks       = ["${aws_subnet.private_with_egress.*.cidr_block[0]}"]

  type      = "egress"
  from_port = "53"
  to_port   = "53"
  protocol  = "udp"
}

# Connections to AWS package repos and GitLab
resource "aws_security_group_rule" "gitlab_runner_egress_http" {
  count       = var.gitlab_on ? 1 : 0
  description = "egress-https"

  security_group_id = aws_security_group.gitlab_runner[count.index].id
  cidr_blocks       = ["0.0.0.0/0"]

  type      = "egress"
  from_port = "80"
  to_port   = "80"
  protocol  = "tcp"
}

# Connections to ECR and CloudWatch
resource "aws_security_group_rule" "gitlab_runner_egress_https" {
  count       = var.gitlab_on ? 1 : 0
  description = "egress-https"

  security_group_id = aws_security_group.gitlab_runner[count.index].id
  cidr_blocks       = ["0.0.0.0/0"]

  type      = "egress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

resource "aws_security_group" "superset_db" {
  name        = "${var.prefix}-superset-db"
  description = "${var.prefix}-superset-db"
  vpc_id      = aws_vpc.notebooks.id

  tags = {
    Name = "${var.prefix}-superset-db"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "superset_service_ingress_http_superset_lb" {
  description = "ingress-superset-lb"

  security_group_id        = aws_security_group.superset_service.id
  source_security_group_id = aws_security_group.superset_lb.id

  type      = "ingress"
  from_port = "8000"
  to_port   = "8000"
  protocol  = "tcp"
}


resource "aws_security_group_rule" "prometheus_service_egress_https_to_ecr_api" {
  description = "egress-https-to-ecr-api"

  security_group_id        = aws_security_group.prometheus_service.id
  source_security_group_id = aws_security_group.ecr_api.id

  type      = "egress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "sentryproxy_service_egress_https_to_ecr_api" {
  description = "egress-https-to-ecr-api"

  security_group_id        = aws_security_group.sentryproxy_service.id
  source_security_group_id = aws_security_group.ecr_api.id

  type      = "egress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

resource "aws_security_group" "superset_lb" {
  name        = "${var.prefix}-superset-lb"
  description = "${var.prefix}-superset-lb"
  vpc_id      = aws_vpc.notebooks.id

  tags = {
    Name = "${var.prefix}-superset-lb"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "superset_lb_ingress_http_admin_service" {
  description = "ingress-http-admin-service"

  security_group_id        = aws_security_group.superset_lb.id
  source_security_group_id = aws_security_group.admin_service.id

  type      = "ingress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "superset_lb_egress_http_superset_service" {
  description = "egress-http-superset-service"

  security_group_id        = aws_security_group.superset_lb.id
  source_security_group_id = aws_security_group.superset_service.id

  type      = "egress"
  from_port = "8000"
  to_port   = "8000"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "airflow_webserver_egress_https_to_cloudwatch" {
  description = "egress-https-to-cloudwatch"

  security_group_id        = aws_security_group.airflow_webserver.id
  source_security_group_id = aws_security_group.cloudwatch.id

  type      = "egress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "airflow_webserver_ingress_http_admin_service" {
  description = "ingress-airflow-lb"

  security_group_id        = aws_security_group.airflow_webserver.id
  source_security_group_id = aws_security_group.admin_service.id

  type      = "ingress"
  from_port = "8080"
  to_port   = "8080"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "airflow_webserver_ingress_http_airflow_webserver_lb" {
  description = "ingress-airflow-lb"

  security_group_id        = aws_security_group.airflow_webserver.id
  source_security_group_id = aws_security_group.airflow_webserver_lb.id

  type      = "ingress"
  from_port = "8080"
  to_port   = "8080"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "airflow_webserver_egress_postgres_airflow_db" {
  description = "egress-postgres-airflow-db"

  security_group_id        = aws_security_group.airflow_webserver.id
  source_security_group_id = aws_security_group.airflow_db.id

  type      = "egress"
  from_port = "5432"
  to_port   = "5432"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "postgres_airflow_db_ingress_airflow_webserver" {
  description = "ingress-airflow-service"

  security_group_id        = aws_security_group.airflow_db.id
  source_security_group_id = aws_security_group.airflow_webserver.id

  type      = "ingress"
  from_port = "5432"
  to_port   = "5432"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "airflow_webserver_lb_egress_http_airflow_webserver" {
  description = "egress-http-airflow-service"

  security_group_id        = aws_security_group.airflow_webserver_lb.id
  source_security_group_id = aws_security_group.airflow_webserver.id

  type      = "egress"
  from_port = "8080"
  to_port   = "8080"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "airflow_egress_https_all" {
  description = "egress-https-to-all"

  security_group_id = aws_security_group.airflow_webserver.id
  cidr_blocks       = ["0.0.0.0/0"]

  type      = "egress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "ecr_api_ingress_https_from_airflow" {
  description = "ingress-https-from-airflow"

  security_group_id        = aws_security_group.ecr_api.id
  source_security_group_id = aws_security_group.airflow_webserver.id

  type      = "ingress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "airflow_webserver_lb_ingress_http_from_whitelist" {
  count       = var.airflow_on ? 1 : 0
  description = "ingress-http-from-whitelist"

  security_group_id = aws_security_group.airflow_webserver_lb.id
  cidr_blocks       = var.gitlab_ip_whitelist

  type      = "ingress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

resource "aws_security_group" "airflow_webserver" {
  name        = "${var.prefix}-airflow-webserver"
  description = "${var.prefix}-airflow-webserver"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.prefix}-airflow-webserver"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "airflow_scheduler" {
  name        = "${var.prefix}-airflow-scheduler"
  description = "${var.prefix}-airflow-scheduler"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.prefix}-airflow-scheduler"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "airflow_scheduler_egress_https_to_ecr_api" {
  description = "egress-https-to-ecr-api"

  security_group_id        = aws_security_group.airflow_scheduler.id
  source_security_group_id = aws_security_group.ecr_api.id

  type      = "egress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "ecr_api_ingress_https_from_airflow_scheduler" {
  description = "ingress-https-from-airflow-scheduler"

  security_group_id        = aws_security_group.ecr_api.id
  source_security_group_id = aws_security_group.airflow_scheduler.id

  type      = "ingress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "airflow_scheduler_egress_https_to_ecs" {
  description = "egress-https-to-ecs"

  security_group_id        = aws_security_group.airflow_scheduler.id
  source_security_group_id = aws_security_group.ecs.id

  type      = "egress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "ecs_ingress_https_from_airflow_scheduler" {
  description = "ingress-https-from-airflow-scheduler"

  security_group_id        = aws_security_group.ecs.id
  source_security_group_id = aws_security_group.airflow_scheduler.id

  type      = "ingress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "ecs_ingress_https_from_airflow_dag_processor" {
  description = "ingress-https-from-airflow-dag-processor"

  security_group_id        = aws_security_group.ecs.id
  source_security_group_id = aws_security_group.airflow_dag_processor_service.id

  type      = "ingress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "airflow_scheduler_egress_https_to_ecr_dkr" {
  description = "egress-https-to-ecr-dkr"

  security_group_id        = aws_security_group.airflow_scheduler.id
  source_security_group_id = aws_security_group.ecr_dkr.id

  type      = "egress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

# S3 is used by ecr-dkr. However, S3 is a gateway endpoint that doesn't have a private IP address
# as interface endpoints. However, there is still a "prefix list" mechanism to restrict egress
resource "aws_security_group_rule" "airflow_scheduler_egress_https_to_s3" {
  description = "egress-https-to-s3"

  security_group_id = aws_security_group.airflow_scheduler.id
  prefix_list_ids   = [aws_vpc_endpoint.main_s3.prefix_list_id]

  type      = "egress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "ecr_dkr_ingress_https_from_airflow_scheduler" {
  description = "ingress-https-airflow-scheduler"

  security_group_id        = aws_security_group.ecr_dkr.id
  source_security_group_id = aws_security_group.airflow_scheduler.id

  type      = "ingress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "airflow_scheduler_egress_https_to_cloudwatch" {
  description = "egress-https-to-cloudwatch"

  security_group_id        = aws_security_group.airflow_scheduler.id
  source_security_group_id = aws_security_group.cloudwatch.id

  type      = "egress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "airflow_scheduler_egress_postgres_airflow_db" {
  description = "egress-postgres-to-airflow-db"

  security_group_id        = aws_security_group.airflow_scheduler.id
  source_security_group_id = aws_security_group.airflow_db.id

  type      = "egress"
  from_port = "5432"
  to_port   = "5432"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "postgres_airflow_db_ingress_airflow_scheduler" {
  description = "ingress-postgres-from-airflow-service"

  security_group_id        = aws_security_group.airflow_db.id
  source_security_group_id = aws_security_group.airflow_scheduler.id

  type      = "ingress"
  from_port = "5432"
  to_port   = "5432"
  protocol  = "tcp"
}


resource "aws_security_group_rule" "airflow_dag_processor_egress_all" {
  description = "egress-to-all"

  security_group_id = aws_security_group.airflow_dag_processor_service.id
  cidr_blocks       = ["0.0.0.0/0"]

  type      = "egress"
  from_port = "0"
  to_port   = "65535"
  protocol  = "tcp"
}


resource "aws_security_group_rule" "ecr_api_ingress_https_from_airflow_dag_processor" {
  description = "ingress-https-from-airflow"

  security_group_id        = aws_security_group.ecr_api.id
  source_security_group_id = aws_security_group.airflow_dag_processor_service.id

  type      = "ingress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}


resource "aws_security_group_rule" "postgres_airflow_db_ingress_airflow_dag_processor_service" {
  description = "ingress-airflow-dag-processor-service"

  security_group_id        = aws_security_group.airflow_db.id
  source_security_group_id = aws_security_group.airflow_dag_processor_service.id

  type      = "ingress"
  from_port = "5432"
  to_port   = "5432"
  protocol  = "tcp"
}

resource "aws_security_group" "airflow_dag_processor_service" {
  name        = "${var.prefix}-airflow-dag-processor-service"
  description = "${var.prefix}-airflow-dag-processor-service"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.prefix}-airflow-dag-processor-service"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "airflow_webserver_lb" {
  name        = "${var.prefix}-airflow-webserver-lb"
  description = "${var.prefix}-airflow-webserver-lb"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.prefix}-airflow-webserver-lb"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "airflow_db" {
  name        = "${var.prefix}-airflow-db"
  description = "${var.prefix}-airflow-db"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.prefix}-airflow-db"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "flower_lb" {
  name        = "${var.prefix}-flower-lb"
  description = "${var.prefix}-flower-lb"
  vpc_id      = aws_vpc.notebooks.id

  tags = {
    Name = "${var.prefix}-flower-lb"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "flower_lb_egress_http_flower_service" {
  description = "egress-http-flower-service"

  security_group_id        = aws_security_group.flower_lb.id
  source_security_group_id = aws_security_group.flower_service.id

  type      = "egress"
  from_port = "80"
  to_port   = "80"
  protocol  = "tcp"
}

resource "aws_security_group" "flower_service" {
  name        = "${var.prefix}-flower-service"
  description = "${var.prefix}-flower-service"
  vpc_id      = aws_vpc.notebooks.id

  tags = {
    Name = "${var.prefix}-flower-service"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "flower_service_ingress_http_flower_lb" {
  description = "ingress-flower-lb"

  security_group_id        = aws_security_group.flower_service.id
  source_security_group_id = aws_security_group.flower_lb.id

  type      = "ingress"
  from_port = "80"
  to_port   = "80"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "flower_service_ingress_admin_redis" {
  description = "ingress-flower-service"

  security_group_id        = aws_security_group.admin_redis.id
  source_security_group_id = aws_security_group.flower_service.id

  type      = "ingress"
  from_port = "6379"
  to_port   = "6379"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "flower_service_egress_admin_redis" {
  description = "egress-redis-admin-redis"

  security_group_id        = aws_security_group.flower_service.id
  source_security_group_id = aws_security_group.admin_redis.id

  type      = "egress"
  from_port = "6379"
  to_port   = "6379"
  protocol  = "tcp"
}

resource "aws_security_group" "efs_notebooks" {
  name        = "${var.prefix}-efs-notebooks"
  description = "${var.prefix}-efs-notebooks"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.prefix}-efs-notebooks"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "efs_mount_target_notebooks" {
  name        = "${var.prefix}-efs-mount-target-notebooks"
  description = "${var.prefix}-efs-mount-target-notebooks"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.prefix}-efs-mount-target-notebooks"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "elasticsearch_ingress_from_admin" {
  description = "ingress-elasticsearch-https-from-admin"

  security_group_id        = aws_security_group.datasets.id
  source_security_group_id = aws_security_group.admin_service.id

  type      = "ingress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "ecr_api_ingress_https_from_flower" {
  description = "ingress-https-from-flower-service"

  security_group_id        = aws_security_group.ecr_api.id
  source_security_group_id = aws_security_group.flower_service.id

  type      = "ingress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "flower_service_egress_https_to_ecr_api" {
  description = "egress-https-to-ecr-api"

  security_group_id        = aws_security_group.flower_service.id
  source_security_group_id = aws_security_group.ecr_api.id

  type      = "egress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "flower_egress_https_all" {
  description = "egress-https-to-all"

  security_group_id = aws_security_group.flower_service.id
  cidr_blocks       = ["0.0.0.0/0"]

  type      = "egress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "flower_service_egress_dns_udp_to_dns_rewrite_proxy" {
  description = "egress-dns-to-dns-rewrite-proxy"

  security_group_id = aws_security_group.flower_service.id
  cidr_blocks       = ["${aws_subnet.private_with_egress.*.cidr_block[0]}"]

  type      = "egress"
  from_port = "53"
  to_port   = "53"
  protocol  = "udp"
}

resource "aws_security_group" "mlflow_service" {
  count       = length(var.mlflow_instances)
  name        = "${var.prefix}-mlflow-${var.mlflow_instances[count.index]}-service"
  description = "${var.prefix}-mlflow-${var.mlflow_instances[count.index]}-service"
  vpc_id      = aws_vpc.notebooks.id

  tags = {
    Name = "${var.prefix}-mlflow-${var.mlflow_instances[count.index]}-service"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "mlflow_service_ingress_http_mlflow_lb" {
  count       = var.mlflow_on ? length(var.mlflow_instances) : 0
  description = "ingress-mlflow-lb"

  security_group_id = aws_security_group.mlflow_service[count.index].id
  cidr_blocks       = ["${aws_lb.mlflow.*.subnet_mapping[count.index].*.private_ipv4_address[0]}/32"]

  type      = "ingress"
  from_port = local.mlflow_port
  to_port   = local.mlflow_port
  protocol  = "tcp"
}

resource "aws_security_group_rule" "mlflow_service_ingress_http_mlflow_dataflow_lb" {
  count       = var.mlflow_on ? length(var.mlflow_instances) : 0
  description = "ingress-mlflow-dataflow-lb"

  security_group_id = aws_security_group.mlflow_service[count.index].id
  cidr_blocks       = ["${aws_lb.mlflow_dataflow.*.subnet_mapping[count.index].*.private_ipv4_address[0]}/32"]

  type      = "ingress"
  from_port = local.mlflow_port
  to_port   = local.mlflow_port
  protocol  = "tcp"
}

resource "aws_security_group_rule" "ecr_api_ingress_https_from_mlflow" {
  count       = length(var.mlflow_instances)
  description = "ingress-https-from-mlflow-${var.mlflow_instances[count.index]}-service"

  security_group_id        = aws_security_group.ecr_api.id
  source_security_group_id = aws_security_group.mlflow_service[count.index].id

  type      = "ingress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "mlflow_service_egress_https_to_ecr_api" {
  count       = length(var.mlflow_instances)
  description = "egress-https-to-ecr-api"

  security_group_id        = aws_security_group.mlflow_service[count.index].id
  source_security_group_id = aws_security_group.ecr_api.id

  type      = "egress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "mlflow_egress_https_all" {
  count       = length(var.mlflow_instances)
  description = "egress-https-to-all"

  security_group_id = aws_security_group.mlflow_service[count.index].id
  cidr_blocks       = ["0.0.0.0/0"]

  type      = "egress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "mlflow_service_egress_dns_udp_to_dns_rewrite_proxy" {
  count       = length(var.mlflow_instances)
  description = "egress-dns-to-dns-rewrite-proxy"

  security_group_id = aws_security_group.mlflow_service[count.index].id
  cidr_blocks       = ["${aws_subnet.private_with_egress.*.cidr_block[0]}"]

  type      = "egress"
  from_port = "53"
  to_port   = "53"
  protocol  = "udp"
}

resource "aws_security_group" "mlflow_db" {
  count       = length(var.mlflow_instances)
  name        = "${var.prefix}-mlflow-${var.mlflow_instances[count.index]}-db"
  description = "${var.prefix}-mlflow-${var.mlflow_instances[count.index]}-db"
  vpc_id      = aws_vpc.notebooks.id

  tags = {
    Name = "${var.prefix}-mlflow-${var.mlflow_instances[count.index]}-db"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "mlflow_db_ingress_postgres_mlflow_service" {
  count       = length(var.mlflow_instances)
  description = "ingress-postgress-mlflow-service-${var.mlflow_instances[count.index]}"

  security_group_id        = aws_security_group.mlflow_db[count.index].id
  source_security_group_id = aws_security_group.mlflow_service[count.index].id

  type      = "ingress"
  from_port = "5432"
  to_port   = "5432"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "mlflow_service_egress_postgres_mlflow_db" {
  count       = length(var.mlflow_instances)
  description = "egress-postgres-mlflow-db"

  security_group_id        = aws_security_group.mlflow_service[count.index].id
  source_security_group_id = aws_security_group.mlflow_db[count.index].id

  type      = "egress"
  from_port = "5432"
  to_port   = "5432"
  protocol  = "tcp"
}

resource "aws_security_group" "ecs" {
  name   = "${var.prefix}-ecs"
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.prefix}-ecs"
  }
}

resource "aws_security_group_rule" "ecs_ingress_https_from_gitlab_ec2" {
  count       = var.gitlab_on ? 1 : 0
  description = "ingress-https-from-gitlab-ec2"

  security_group_id        = aws_security_group.ecs.id
  source_security_group_id = aws_security_group.gitlab-ec2[count.index].id

  type      = "ingress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "ecs_ingress_https_from_admin_service" {
  description = "ingress-https-from-admin-service"

  security_group_id        = aws_security_group.ecs.id
  source_security_group_id = aws_security_group.admin_service.id

  type      = "ingress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

resource "aws_security_group" "arango_lb" {
  count       = var.arango_on ? 1 : 0
  name        = "${var.prefix}-arango_lb"
  description = "${var.prefix}-arango_lb"
  vpc_id      = aws_vpc.datasets.id

  tags = {
    Name = "${var.prefix}-arango_lb"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "arango_lb_egress_https_to_arango_service" {
  count       = var.arango_on ? 1 : 0
  description = "egress-https-to-arango-service"

  security_group_id        = aws_security_group.arango_lb[0].id
  source_security_group_id = aws_security_group.arango_service[0].id

  type      = "egress"
  from_port = local.arango_container_port
  to_port   = local.arango_container_port
  protocol  = "tcp"
}

resource "aws_security_group_rule" "arango_lb_ingress_arango_from_admin-service" {
  count       = var.arango_on ? 1 : 0
  description = "ingress-arrango-from-admin_service"

  security_group_id        = aws_security_group.arango_lb[0].id
  source_security_group_id = aws_security_group.admin_service.id

  type      = "ingress"
  from_port = "8529"
  to_port   = "8529"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "arango_lb_egress_https_to_cloudwatch" {
  count       = var.arango_on ? 1 : 0
  description = "egress-https-to-cloudwatch"

  security_group_id        = aws_security_group.arango_lb[0].id
  source_security_group_id = aws_security_group.cloudwatch.id

  type      = "egress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

resource "aws_security_group" "arango_service" {
  count       = var.arango_on ? 1 : 0
  name        = "${var.prefix}-arango"
  description = "${var.prefix}-arango"
  vpc_id      = aws_vpc.datasets.id

  tags = {
    Name = "${var.prefix}-arango"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# S3 is used by ecr-dkr. However, S3 is a gateway endpoint that doesn't have a private IP address
# as interface endpoints. However, there is still a "prefix list" mechanism to restrict egress
resource "aws_security_group_rule" "arango_ec2_egress_https_to_s3" {
  count       = var.arango_on ? 1 : 0
  description = "egress-https-to-s3"

  security_group_id = aws_security_group.arango-ec2[0].id
  prefix_list_ids   = [aws_vpc_endpoint.datasets_s3_endpoint[0].prefix_list_id]

  type      = "egress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "arango_service_egress_https_datasets_endpoints" {
  count       = var.arango_on ? 1 : 0
  description = "egress-ec2-agent"

  security_group_id        = aws_security_group.arango_service[0].id
  source_security_group_id = aws_security_group.datasets_endpoints.id

  type      = "egress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "arango_service_ingress_arango_lb" {
  count       = var.arango_on ? 1 : 0
  description = "ingress-arango-lb"

  security_group_id        = aws_security_group.arango_service[0].id
  source_security_group_id = aws_security_group.arango_lb[0].id

  type      = "ingress"
  from_port = "8529"
  to_port   = "8529"
  protocol  = "tcp"
}

resource "aws_security_group" "arango-ec2" {
  count       = var.arango_on ? 1 : 0
  name        = "${var.prefix}-arango-ec2"
  description = "${var.prefix}-arango-ec2"
  vpc_id      = aws_vpc.datasets.id

  tags = {
    Name = "${var.prefix}-arango-ec2"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "arango_ec2_egress_https_datasets_endpoints" {
  count       = var.arango_on ? 1 : 0
  description = "egress-ec2-agent"

  security_group_id        = aws_security_group.arango-ec2[0].id
  source_security_group_id = aws_security_group.datasets_endpoints.id

  type      = "egress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

resource "aws_security_group" "datasets_endpoints" {
  name        = "${var.prefix}-datasets-endpoints"
  description = "${var.prefix}-datasets-endpoints"
  vpc_id      = aws_vpc.datasets.id

  tags = {
    Name = "${var.prefix}-datasets-endpoints"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "datasets_endpoint_ingress_arango_ec2" {
  count       = var.arango_on ? 1 : 0
  description = "endpoint-ingress-from-datasets-vpc"

  security_group_id        = aws_security_group.datasets_endpoints.id
  source_security_group_id = aws_security_group.arango-ec2[0].id

  type      = "ingress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "datasets_endpoint_ingress_arango_service" {
  count       = var.arango_on ? 1 : 0
  description = "endpoint-ingress-from-datasets-vpc"

  security_group_id        = aws_security_group.datasets_endpoints.id
  source_security_group_id = aws_security_group.arango_service[0].id

  type      = "ingress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

resource "aws_security_group" "airflow_resource_endpoints" {
  count       = length(var.airflow_resource_endpoints)
  name        = "${var.prefix}-airflow-resource-endpoints-${count.index}"
  description = "${var.prefix}-airflow-resource-endpoints-${count.index}"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.prefix}-airflow-resource-endpoints-endpoints-${count.index}"
  }
}

resource "aws_security_group_rule" "airflow_resource_endpoints_ingress_from_dag" {
  count             = length(var.airflow_resource_endpoints)
  security_group_id = aws_security_group.airflow_resource_endpoints[count.index].id

  # This security is also used by Airflow tasks
  source_security_group_id = aws_security_group.airflow_dag_processor_service.id

  type      = "ingress"
  from_port = var.airflow_resource_endpoints[count.index].port
  to_port   = var.airflow_resource_endpoints[count.index].port
  protocol  = "tcp"
}

resource "aws_security_group_rule" "airflow_dag_egress_to_resource_endpoints" {
  count = length(var.airflow_resource_endpoints)

  # This security is also used by Airflow tasks
  security_group_id        = aws_security_group.airflow_dag_processor_service.id
  source_security_group_id = aws_security_group.airflow_resource_endpoints[count.index].id

  type      = "egress"
  from_port = var.airflow_resource_endpoints[count.index].port
  to_port   = var.airflow_resource_endpoints[count.index].port
  protocol  = "tcp"
}
