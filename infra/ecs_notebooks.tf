resource "aws_ecs_cluster" "notebooks" {
  name = "${var.prefix}-notebooks"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}
