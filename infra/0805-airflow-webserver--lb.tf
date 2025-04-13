resource "aws_eip" "airflow_webserver" {
  count = var.airflow_on ? 1 : 0
  vpc   = true

  lifecycle {
    # VPN routing may depend on this
    prevent_destroy = false
  }
}

resource "aws_lb" "airflow_webserver" {
  count                      = var.airflow_on ? 1 : 0
  name                       = "${var.prefix}-af-ws" # Having airflow-webserver in the name makes it > the limit of 32
  load_balancer_type         = "network"
  internal                   = false
  security_groups            = ["${aws_security_group.airflow_webserver_lb.id}"]
  enable_deletion_protection = true

  subnet_mapping {
    subnet_id     = aws_subnet.public.*.id[0]
    allocation_id = aws_eip.airflow_webserver[0].id
  }
}

resource "aws_lb_listener" "airflow_webserver_443" {
  count             = var.airflow_on ? 1 : 0
  load_balancer_arn = aws_lb.airflow_webserver[count.index].arn
  port              = "443"
  protocol          = "TLS"

  ssl_policy      = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn = aws_acm_certificate_validation.airflow_webserver[count.index].certificate_arn

  default_action {
    target_group_arn = aws_lb_target_group.airflow_webserver_8080[count.index].arn
    type             = "forward"
  }
}

resource "aws_lb_target_group" "airflow_webserver_8080" {
  count       = var.airflow_on ? 1 : 0
  name_prefix = "s8080-"
  port        = "8080"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
  protocol    = "TCP"

  health_check {
    protocol            = "TCP"
    timeout             = 15
    interval            = 20
    healthy_threshold   = 2
    unhealthy_threshold = 5
  }

  lifecycle {
    create_before_destroy = true
  }
}
