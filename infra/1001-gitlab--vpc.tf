resource "aws_eip" "gitlab" {
  count = var.gitlab_on ? 1 : 0
  vpc   = true

  lifecycle {
    # VPN routing may depend on this
    prevent_destroy = false
  }
}
