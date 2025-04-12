resource "aws_lb" "arango" {
  count                      = var.arango_on ? 1 : 0
  name                       = "${var.prefix}-arango"
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.arango_lb[0].id]
  enable_deletion_protection = true
  internal                   = true
  subnets                    = aws_subnet.datasets.*.id
  idle_timeout               = 360
  tags = {
    name = "arango-to-notebook-lb"
  }
}

resource "aws_lb_listener" "arango" {
  count             = var.arango_on ? 1 : 0
  load_balancer_arn = aws_lb.arango[0].arn
  port              = "8529"
  protocol          = "HTTPS"

  ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn = aws_acm_certificate_validation.arango[count.index].certificate_arn

  default_action {
    target_group_arn = aws_lb_target_group.arango[0].id
    type             = "forward"
  }
}

resource "aws_lb_target_group" "arango" {
  count       = var.arango_on ? 1 : 0
  name        = "${var.prefix}-arango"
  port        = "8529"
  vpc_id      = aws_vpc.datasets.id
  target_type = "ip"
  protocol    = "HTTP"

  health_check {
    protocol            = "HTTP"
    interval            = 45
    timeout             = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
    path                = "/_db/_system/_admin/aardvark/index.html"
  }
}
