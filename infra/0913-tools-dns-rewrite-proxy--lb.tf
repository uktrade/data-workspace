resource "aws_lb" "dns_rewrite_proxy_new" {
  # should be suffixed `dns-rewrite-proxy` but name is limited to 32 chars, and that is too long
  # for `analysisworkspace-dev-dns-rewrite-proxy`
  name                             = "${var.prefix}-dnsproxy2"
  load_balancer_type               = "network"
  enable_cross_zone_load_balancing = "true"
  enable_deletion_protection       = true
  internal                         = true

  subnet_mapping {
    subnet_id            = aws_subnet.private_with_egress.*.id[0]
    private_ipv4_address = cidrhost("${aws_subnet.private_with_egress.*.cidr_block[0]}", 7)
  }
}

resource "aws_lb_listener" "dns_rewrite_proxy_new" {
  load_balancer_arn = aws_lb.dns_rewrite_proxy_new.id
  port              = 53
  protocol          = "UDP"

  default_action {
    target_group_arn = aws_lb_target_group.dns_rewrite_proxy_new.id
    type             = "forward"
  }
}

resource "aws_lb_target_group" "dns_rewrite_proxy_new" {
  # should be suffixed `dns-rewrite-proxy` but name is limited to 32 chars, and that is too long
  # for `analysisworkspace-dev-dns-rewrite-proxy`
  name        = "${var.prefix}-dnsproxy2"
  port        = 53
  protocol    = "UDP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    protocol = "HTTP"
    port     = "8888"
    path     = "/"
  }

  depends_on = [aws_lb.dns_rewrite_proxy_new]
}
