# This had enable_deletion_protection enabled. Have disabled it, and once this has been applied
# to all environments, it can be removed
resource "aws_lb" "dns_rewrite_proxy" {
  # should be suffixed `dns-rewrite-proxy` but name is limited to 32 chars, and that is too long
  # for `analysisworkspace-dev-dns-rewrite-proxy`
  name                             = "${var.prefix}-dns-proxy"
  load_balancer_type               = "network"
  enable_cross_zone_load_balancing = "true"
  enable_deletion_protection       = false

  internal = true

  subnet_mapping {
    subnet_id            = aws_subnet.private_with_egress.*.id[0]
    private_ipv4_address = cidrhost("${aws_subnet.private_with_egress.*.cidr_block[0]}", 5)
  }
}
