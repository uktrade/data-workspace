resource "aws_alb" "prometheus" {
  name                       = "${var.prefix}-pm"
  subnets                    = aws_subnet.public.*.id
  security_groups            = ["${aws_security_group.prometheus_alb.id}"]
  enable_deletion_protection = true
  timeouts {}

  access_logs {
    bucket  = aws_s3_bucket.alb_access_logs.id
    prefix  = "prometheus"
    enabled = true
  }

  depends_on = [
    aws_s3_bucket_policy.alb_access_logs,
  ]
}

resource "aws_alb_listener" "prometheus" {
  load_balancer_arn = aws_alb.prometheus.arn
  port              = local.prometheus_alb_port
  protocol          = "HTTPS"

  default_action {
    target_group_arn = aws_alb_target_group.prometheus.arn
    type             = "forward"
  }

  ssl_policy      = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn = aws_acm_certificate_validation.prometheus.certificate_arn
}

resource "aws_alb_target_group" "prometheus" {
  name_prefix = "pm-"
  port        = local.prometheus_container_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = "/-/healthy"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  lifecycle {
    create_before_destroy = true
  }
}
