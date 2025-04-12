resource "aws_alb" "admin" {
  name                       = "${var.prefix}-admin"
  subnets                    = aws_subnet.public.*.id
  security_groups            = ["${aws_security_group.admin_alb.id}"]
  enable_deletion_protection = true
  timeouts {}

  access_logs {
    bucket  = aws_s3_bucket.alb_access_logs.id
    prefix  = "admin"
    enabled = true
  }

  depends_on = [
    aws_s3_bucket_policy.alb_access_logs,
  ]
}

resource "aws_alb_listener" "admin" {
  load_balancer_arn = aws_alb.admin.arn
  port              = local.admin_alb_port
  protocol          = "HTTPS"

  default_action {
    target_group_arn = aws_alb_target_group.admin.arn
    type             = "forward"
  }

  ssl_policy      = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn = aws_acm_certificate_validation.admin.certificate_arn
}

resource "aws_alb_listener" "admin_http" {
  load_balancer_arn = aws_alb.admin.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.admin.arn
    type             = "forward"
  }
}

resource "aws_alb_target_group" "admin" {
  name_prefix          = "jhadm-"
  port                 = local.admin_container_port
  protocol             = "HTTP"
  vpc_id               = aws_vpc.main.id
  target_type          = "ip"
  deregistration_delay = var.admin_deregistration_delay

  health_check {
    path                = "/healthcheck"
    protocol            = "HTTP"
    healthy_threshold   = 3
    unhealthy_threshold = 2
    timeout             = 30
    interval            = 40
  }

  lifecycle {
    create_before_destroy = true
  }
}
