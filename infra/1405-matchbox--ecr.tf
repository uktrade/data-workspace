resource "aws_ecr_repository" "matchbox" {
  count = var.matchbox_on ? 1 : 0
  name  = "${var.prefix}-matchbox"
}
