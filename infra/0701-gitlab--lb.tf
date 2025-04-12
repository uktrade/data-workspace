resource "aws_lb" "gitlab" {
  count                      = var.gitlab_on ? 1 : 0
  name                       = "${var.prefix}-gitlab"
  load_balancer_type         = "network"
  enable_deletion_protection = true

  subnet_mapping {
    subnet_id     = aws_subnet.public.*.id[0]
    allocation_id = aws_eip.gitlab[count.index].id
  }
}

resource "aws_lb_listener" "gitlab_443" {
  count             = var.gitlab_on ? 1 : 0
  load_balancer_arn = aws_lb.gitlab[count.index].arn
  port              = "443"
  protocol          = "TLS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate.gitlab[count.index].arn

  default_action {
    target_group_arn = aws_lb_target_group.gitlab_80[count.index].arn
    type             = "forward"
  }
}

resource "aws_lb_listener" "gitlab_22" {
  count             = var.gitlab_on ? 1 : 0
  load_balancer_arn = aws_lb.gitlab[count.index].arn
  port              = "22"
  protocol          = "TCP"

  default_action {
    target_group_arn = aws_lb_target_group.gitlab_22[count.index].arn
    type             = "forward"
  }
}

resource "aws_lb_target_group" "gitlab_80" {
  count              = var.gitlab_on ? 1 : 0
  name_prefix        = "gl80-"
  port               = "80"
  vpc_id             = aws_vpc.main.id
  target_type        = "ip"
  protocol           = "TCP"
  preserve_client_ip = true

  health_check {
    protocol            = "TCP"
    interval            = 10
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "gitlab_22" {
  count              = var.gitlab_on ? 1 : 0
  name_prefix        = "gl22-"
  port               = "22"
  vpc_id             = aws_vpc.main.id
  target_type        = "ip"
  protocol           = "TCP"
  preserve_client_ip = true

  health_check {
    protocol            = "TCP"
    interval            = 10
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  lifecycle {
    create_before_destroy = true
  }
}
