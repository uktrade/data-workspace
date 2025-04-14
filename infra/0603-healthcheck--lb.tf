
resource "aws_alb" "healthcheck" {
  name                       = "${var.prefix}-hc"
  subnets                    = aws_subnet.public.*.id
  security_groups            = ["${aws_security_group.healthcheck_alb.id}"]
  enable_deletion_protection = true
  timeouts {}

  access_logs {
    bucket  = aws_s3_bucket.alb_access_logs.id
    prefix  = "healthcheck"
    enabled = true
  }

  depends_on = [
    aws_s3_bucket_policy.alb_access_logs,
  ]
}

resource "aws_alb_listener" "healthcheck" {
  load_balancer_arn = aws_alb.healthcheck.arn
  port              = local.healthcheck_alb_port
  protocol          = "HTTPS"

  default_action {
    target_group_arn = aws_alb_target_group.healthcheck.arn
    type             = "forward"
  }

  ssl_policy      = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn = aws_acm_certificate_validation.healthcheck.certificate_arn
}

resource "aws_alb_target_group" "healthcheck" {
  name_prefix = "ck-"
  port        = local.healthcheck_container_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = "/check_alb"
    protocol            = "HTTP"
    healthy_threshold   = 3
    unhealthy_threshold = 2
  }

  lifecycle {
    create_before_destroy = true
  }
}
