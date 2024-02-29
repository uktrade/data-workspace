resource "aws_ecs_service" "arango" {
  name            = "${var.prefix}-arango"
  cluster         = "${aws_ecs_cluster.main_cluster.id}"
  task_definition = "${aws_ecs_task_definition.arango_service.arn}"
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = ["${aws_subnet.private_with_egress.*.id[0]}"]
    security_groups = ["${aws_security_group.arango_service.id}"]
  }

  load_balancer {
    target_group_arn = "${aws_lb_target_group.arango.arn}"
    container_port   = "8529"
    container_name   = "arango"
  }

  depends_on = [
    # The target group must have been associated with the listener first
    "aws_lb_listener.arango",
  ]
}

resource "aws_ecs_task_definition" "arango_service" {
  family                   = "${var.prefix}-arango"
  container_definitions    = "${data.template_file.arango_service_container_definitions.rendered}"
  execution_role_arn       = "${aws_iam_role.arango_task_execution.arn}"
  task_role_arn            = "${aws_iam_role.arango_task.arn}"
  network_mode             = "awsvpc"
  cpu                      = "${local.arango_container_cpu}"
  memory                   = "${local.arango_container_memory}"
  requires_compatibilities = ["FARGATE"]

  lifecycle {
    ignore_changes = [
      "revision",
    ]
  }
}

data "template_file" "arango_service_container_definitions" {
  template = "${file("${path.module}/ecs_main_arango_container_definitions.json")}"

  vars = {
    container_image = "339713044404.dkr.ecr.eu-west-2.amazonaws.com/data-workspace-dev-a-arango:latest"
    container_name  = "arango"
    log_group       = "${aws_cloudwatch_log_group.arango.name}"
    log_region      = "${data.aws_region.aws_region.name}"
    cpu             = "${local.arango_container_cpu}"
    memory          = "${local.arango_container_memory}"
  }
}

resource "aws_cloudwatch_log_group" "arango" {
  name              = "${var.prefix}-arango"
  retention_in_days = "3653"
}

resource "aws_iam_role" "arango_task_execution" {
  name               = "${var.prefix}-arango-task-execution"
  path               = "/"
  assume_role_policy = "${data.aws_iam_policy_document.arango_task_execution_ecs_tasks_assume_role.json}"
}

data "aws_iam_policy_document" "arango_task_execution_ecs_tasks_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "arango_task_execution" {
  role       = "${aws_iam_role.arango_task_execution.name}"
  policy_arn = "${aws_iam_policy.arango_task_execution.arn}"
}

resource "aws_iam_policy" "arango_task_execution" {
  name   = "${var.prefix}-arango-task-execution"
  path   = "/"
  policy = "${data.aws_iam_policy_document.arango_task_execution.json}"
}

data "aws_iam_policy_document" "arango_task_execution" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "${aws_cloudwatch_log_group.arango.arn}:*",
    ]
  }

  statement {
    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]

    resources = [
      "${aws_ecr_repository.arango.arn}",
    ]
  }

  statement {
    actions = [
      "ecr:GetAuthorizationToken",
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_role" "arango_task" {
  name               = "${var.prefix}-arango-task"
  path               = "/"
  assume_role_policy = "${data.aws_iam_policy_document.arango_task_ecs_tasks_assume_role.json}"
}

data "aws_iam_policy_document" "arango_task_ecs_tasks_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "arango_ecs" {
  name               = "${var.prefix}-arango-ecs"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.arango_ecs_assume_role.json
}

resource "aws_iam_role_policy_attachment" "arango_ecs" {
  role       = aws_iam_role.arango_ecs.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}

data "aws_iam_policy_document" "arango_ecs_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}

resource "aws_lb" "arango" {
  name               = "${var.prefix}-arango"
  load_balancer_type = "network"
  security_groups = ["${aws_security_group.arango_lb.id}"]
  enable_deletion_protection = true
  timeouts {}

  subnet_mapping {
    subnet_id     = "${aws_subnet.public.*.id[0]}"
    
  }
}

resource "aws_lb_listener" "arango" {
  load_balancer_arn = "${aws_lb.arango.arn}"
  port              = "8529"
  protocol          = "TCP"

  default_action {
    target_group_arn = "${aws_lb_target_group.arango.id}"
    type             = "forward"
  }
}

resource "aws_lb_target_group" "arango" {
  name = "${var.prefix}-arango"
  port        = "8529"
  vpc_id      = "${aws_vpc.main.id}"
  target_type = "ip"
  protocol    = "TCP"
  preserve_client_ip = true

  health_check {
    protocol = "TCP"
    interval = 10
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}