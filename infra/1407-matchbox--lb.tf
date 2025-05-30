resource "aws_lb" "matchbox" {
  count              = var.matchbox_on ? 1 : 0
  name               = "${var.prefix}-matchbox"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.matchbox_lb[0].id]
  internal           = true
  subnets            = aws_subnet.matchbox_private.*.id
  idle_timeout       = 300
  tags = {
    name = "matchbox-to-notebook-lb"
  }
}

resource "aws_lb_listener" "matchbox" {
  count             = var.matchbox_on ? 1 : 0
  load_balancer_arn = aws_lb.matchbox[count.index].arn
  port              = local.matchbox_api_port
  protocol          = "HTTPS"

  ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn = aws_acm_certificate_validation.matchbox[count.index].certificate_arn

  default_action {
    target_group_arn = aws_lb_target_group.matchbox[0].id
    type             = "forward"
  }
}

resource "aws_lb_target_group" "matchbox" {
  count       = var.matchbox_on ? 1 : 0
  name        = "${var.prefix}-matchbox"
  port        = local.matchbox_api_port
  vpc_id      = aws_vpc.matchbox[count.index].id
  target_type = "ip"
  protocol    = "HTTP"

  health_check {
    protocol            = "HTTP"
    port                = local.matchbox_api_port
    interval            = 45
    timeout             = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
    path                = "/health"
  }
}

resource "aws_security_group" "matchbox_lb" {
  count       = var.matchbox_on ? 1 : 0
  name        = "${var.prefix}-matchbox_lb"
  description = "${var.prefix}-matchbox_lb"
  vpc_id      = aws_vpc.matchbox[count.index].id

  tags = {
    Name = "${var.prefix}-matchbox_lb"
  }

  lifecycle {
    create_before_destroy = true
  }
}

module "matchbox_lb_outgoing_matchbox_api" {
  count  = var.matchbox_on ? 1 : 0
  source = "./modules/security_group_client_server_connections"

  client_security_groups = [aws_security_group.matchbox_lb[count.index]]
  server_security_groups = [aws_security_group.matchbox_service[count.index]]
  ports                  = [local.matchbox_api_port]
}

resource "aws_service_discovery_service" "matchbox_lb" {
  name = "matchbox"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.jupyterhub.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "WEIGHTED"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_service_discovery_instance" "matchbox_lb" {
  count       = var.matchbox_on ? 1 : 0
  instance_id = "${var.prefix}-matchbox-lb"
  service_id  = aws_service_discovery_service.matchbox_lb.id

  attributes = {
    AWS_ALIAS_DNS_NAME = aws_lb.matchbox[count.index].dns_name
  }
}