resource "aws_lb" "flower" {
  name                       = "${var.prefix}-flower"
  load_balancer_type         = "application"
  internal                   = true
  security_groups            = ["${aws_security_group.flower_lb.id}"]
  subnets                    = aws_subnet.private_without_egress.*.id
  enable_deletion_protection = true
}

resource "aws_lb_listener" "flower_80" {
  load_balancer_arn = aws_lb.flower.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.flower_80.arn
    type             = "forward"
  }
}

resource "aws_lb_target_group" "flower_80" {
  name_prefix = "f80-"
  port        = "80"
  vpc_id      = aws_vpc.notebooks.id
  target_type = "ip"
  protocol    = "HTTP"

  health_check {
    protocol            = "HTTP"
    interval            = 10
    healthy_threshold   = 2
    unhealthy_threshold = 5

    path = "/healthcheck"
  }

  lifecycle {
    create_before_destroy = true
  }
}
