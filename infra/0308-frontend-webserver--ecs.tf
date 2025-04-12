resource "aws_ecs_service" "admin" {
  name                       = "${var.prefix}-admin"
  cluster                    = aws_ecs_cluster.main_cluster.id
  task_definition            = aws_ecs_task_definition.admin.arn
  desired_count              = var.admin_instances
  launch_type                = "FARGATE"
  platform_version           = "1.4.0"
  deployment_maximum_percent = 600
  timeouts {}

  network_configuration {
    subnets         = aws_subnet.private_with_egress.*.id
    security_groups = ["${aws_security_group.admin_service.id}"]
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.admin.arn
    container_port   = local.admin_container_port
    container_name   = local.admin_container_name
  }

  service_registries {
    registry_arn = aws_service_discovery_service.admin.arn
  }

  depends_on = [
    # The target group must have been associated with the listener first
    aws_alb_listener.admin,
  ]
}

resource "aws_service_discovery_service" "admin" {
  name = "${var.prefix}-admin"
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.jupyterhub.id
    dns_records {
      ttl  = 10
      type = "A"
    }
  }

  # Needed for a service to be able to register instances with a target group,
  # but only if it has a service_registries, which we do
  # https://forums.aws.amazon.com/thread.jspa?messageID=852407&tstart=0
  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_ecs_task_definition" "admin" {
  family = "${var.prefix}-admin"
  container_definitions = templatefile(
    "${path.module}/ecs_main_admin_container_definitions.json",
    merge(local.admin_container_vars, tomap({ "container_command" = "[\"/dataworkspace/start.sh\"]" }))
  )
  execution_role_arn       = aws_iam_role.admin_task_execution.arn
  task_role_arn            = aws_iam_role.admin_task.arn
  network_mode             = "awsvpc"
  cpu                      = local.admin_container_cpu
  memory                   = local.admin_container_memory
  requires_compatibilities = ["FARGATE"]

  lifecycle {
    ignore_changes = [
      revision,
    ]
  }
}
