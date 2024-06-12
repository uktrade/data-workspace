resource "aws_ecs_service" "airflow_webserver" {
  count                             = var.airflow_on ? 1 : 0
  name                              = "${var.prefix}-airflow-webserver"
  cluster                           = aws_ecs_cluster.main_cluster.id
  task_definition                   = aws_ecs_task_definition.airflow_webserver[count.index].arn
  desired_count                     = 1
  launch_type                       = "FARGATE"
  deployment_maximum_percent        = 200
  platform_version                  = "1.4.0"
  health_check_grace_period_seconds = "10"

  network_configuration {
    subnets         = ["${aws_subnet.private_with_egress.*.id[0]}"]
    security_groups = ["${aws_security_group.airflow_webserver.id}"]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.airflow_webserver_8080[count.index].arn
    container_port   = "8080"
    container_name   = "airflow"
  }

  depends_on = [
    aws_lb_listener.airflow_webserver_443,
  ]
}

resource "aws_lb" "airflow_webserver" {
  count                      = var.airflow_on ? 1 : 0
  name                       = "${var.prefix}-af-ws" # Having airflow-webserver in the name makes it > the limit of 32
  load_balancer_type         = "application"
  internal                   = false
  security_groups            = ["${aws_security_group.airflow_webserver_lb.id}"]
  subnets                    = aws_subnet.public.*.id
  enable_deletion_protection = true
}

resource "aws_lb_listener" "airflow_webserver_443" {
  count             = var.airflow_on ? 1 : 0
  load_balancer_arn = aws_lb.airflow_webserver[count.index].arn
  port              = "443"
  protocol          = "HTTPS"

  ssl_policy      = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn = aws_acm_certificate_validation.airflow_webserver[count.index].certificate_arn

  default_action {
    target_group_arn = aws_lb_target_group.airflow_webserver_8080[count.index].arn
    type             = "forward"
  }
}

resource "aws_lb_target_group" "airflow_webserver_8080" {
  count       = var.airflow_on ? 1 : 0
  name_prefix = "s8080-"
  port        = "8080"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
  protocol    = "HTTP"

  health_check {
    protocol            = "HTTP"
    timeout             = 15
    interval            = 20
    healthy_threshold   = 2
    unhealthy_threshold = 5

    path = "/health"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_ecs_task_definition" "airflow_webserver" {
  count  = var.airflow_on ? 1 : 0
  family = "${var.prefix}-airflow"
  container_definitions = templatefile(
    "${path.module}/airflow_webserver_container_definitions.json", {
      command = "[\"airflow\",\"webserver\",\"-p 8080\"]"

      container_image = "${aws_ecr_repository.airflow.repository_url}:master"
      container_name  = "airflow"
      log_group       = "${aws_cloudwatch_log_group.airflow_webserver[count.index].name}"
      log_region      = "${data.aws_region.aws_region.name}"
      cpu             = "${local.airflow_container_cpu}"
      memory          = "${local.airflow_container_memory}"

      db_host     = "${aws_rds_cluster.airflow[count.index].endpoint}"
      db_name     = "${aws_rds_cluster.airflow[count.index].database_name}"
      db_password = "${random_string.aws_db_instance_airflow_password.result}"
      db_port     = "${aws_rds_cluster.airflow[count.index].port}"
      db_user     = "${aws_rds_cluster.airflow[count.index].master_username}"
      secret_key  = "${random_string.airflow_secret_key.result}"

      datasets_db_host     = "${aws_rds_cluster.datasets.endpoint}"
      datasets_db_name     = "${aws_rds_cluster.datasets.database_name}"
      datasets_db_password = "${random_string.aws_rds_cluster_instance_datasets_password.result}"
      datasets_db_port     = "${aws_rds_cluster.datasets.port}"
      datasets_db_user     = "${var.datasets_rds_cluster_master_username}"

      sentry_dsn         = "${var.sentry_notebooks_dsn}"
      sentry_environment = "${var.sentry_environment}"

      authbroker_url           = "${var.airflow_authbroker_url}"
      authbroker_client_id     = "${var.airflow_authbroker_client_id}"
      authbroker_client_secret = "${var.airflow_authbroker_client_secret}"

      subnets         = "${aws_subnet.private_with_egress.*.id[0]}"
      security_groups = "${aws_security_group.airflow_webserver.id}"
      task_definition = "${aws_ecs_task_definition.airflow_dag_tasks[0].arn}"
      cluster         = "${aws_ecs_cluster.notebooks.name}"

      cloudwatch_log_group_arn = "${aws_cloudwatch_log_group.airflow_dag_tasks_airflow_logging[0].arn}"

      dag_sync_github_key = "${var.dag_sync_github_key}"
    }
  )
  execution_role_arn       = aws_iam_role.airflow_webserver_execution[count.index].arn
  task_role_arn            = aws_iam_role.airflow_webserver_task[count.index].arn
  network_mode             = "awsvpc"
  cpu                      = local.airflow_container_cpu
  memory                   = local.airflow_container_memory
  requires_compatibilities = ["FARGATE"]

  lifecycle {
    ignore_changes = [
      "revision",
    ]
  }
}

resource "aws_cloudwatch_log_group" "airflow_webserver" {
  count             = var.airflow_on ? 1 : 0
  name              = "${var.prefix}-airflow-webserver"
  retention_in_days = "3653"
}

resource "aws_cloudwatch_log_subscription_filter" "airflow" {
  count           = var.cloudwatch_subscription_filter && var.airflow_on ? 1 : 0
  name            = "${var.prefix}-airflow"
  log_group_name  = aws_cloudwatch_log_group.airflow_webserver[count.index].name
  filter_pattern  = ""
  destination_arn = var.cloudwatch_destination_arn
}

resource "aws_iam_role" "airflow_webserver_execution" {
  count              = var.airflow_on ? 1 : 0
  name               = "${var.prefix}-airflow-webserver-execution"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.airflow_webserver_execution_ecs_tasks_assume_role[count.index].json
}

resource "aws_iam_role" "airflow_webserver_task" {
  count              = var.airflow_on ? 1 : 0
  name               = "${var.prefix}-airflow-webserver-task"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.airflow_webserver_task_ecs_tasks_assume_role[count.index].json
}

data "aws_iam_policy_document" "airflow_webserver_execution_ecs_tasks_assume_role" {
  count = var.airflow_on ? 1 : 0
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "airflow_webserver_execution" {
  count      = var.airflow_on ? 1 : 0
  role       = aws_iam_role.airflow_webserver_execution[count.index].name
  policy_arn = aws_iam_policy.airflow_webserver_execution[count.index].arn
}

resource "aws_iam_policy" "airflow_webserver_execution" {
  count  = var.airflow_on ? 1 : 0
  name   = "${var.prefix}-airflow-execution"
  path   = "/"
  policy = data.aws_iam_policy_document.airflow_webserver_execution[count.index].json
}

data "aws_iam_policy_document" "airflow_webserver_task_ecs_tasks_assume_role" {
  count = var.airflow_on ? 1 : 0
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "airflow_ecs" {
  count              = var.airflow_on ? 1 : 0
  name               = "${var.prefix}-airflow-ecs"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.airflow_ecs_assume_role[count.index].json
}

resource "aws_iam_role_policy_attachment" "airflow_ecs" {
  count      = var.airflow_on ? 1 : 0
  role       = aws_iam_role.airflow_ecs[count.index].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}

resource "aws_iam_role_policy_attachment" "airflow_webserver_task" {
  count      = var.airflow_on ? 1 : 0
  role       = aws_iam_role.airflow_webserver_task[count.index].name
  policy_arn = aws_iam_policy.airflow_webserver_task[0].arn
}

resource "aws_iam_policy" "airflow_webserver_task" {
  count  = var.airflow_on ? 1 : 0
  name   = "${var.prefix}-airflow-task"
  path   = "/"
  policy = data.aws_iam_policy_document.airflow_webserver_task[0].json
}

data "aws_iam_policy_document" "airflow_ecs_assume_role" {
  count = var.airflow_on ? 1 : 0
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}


data "aws_iam_policy_document" "airflow_webserver_execution" {
  count = var.airflow_on ? 1 : 0
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "${aws_cloudwatch_log_group.airflow_webserver[count.index].arn}:*",
    ]
  }

  statement {
    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]

    resources = [
      "${aws_ecr_repository.airflow.arn}",
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

data "aws_iam_policy_document" "airflow_webserver_task" {
  count = var.airflow_on ? 1 : 0

  statement {
    actions = [
      "ecs:DescribeClusters"
    ]

    resources = [
      "arn:aws:ecs:${data.aws_region.aws_region.name}:${data.aws_caller_identity.aws_caller_identity.account_id}:cluster/${aws_ecs_cluster.notebooks.name}",
    ]
  }

  statement {
    actions = [
      "ecs:RunTask",
    ]

    condition {
      test     = "ArnEquals"
      variable = "ecs:cluster"
      values = [
        "arn:aws:ecs:${data.aws_region.aws_region.name}:${data.aws_caller_identity.aws_caller_identity.account_id}:cluster/${aws_ecs_cluster.notebooks.name}",
      ]
    }

    resources = [
      "arn:aws:ecs:${data.aws_region.aws_region.name}:${data.aws_caller_identity.aws_caller_identity.account_id}:task-definition/${aws_ecs_task_definition.airflow_webserver[0].family}",
      "arn:aws:ecs:${data.aws_region.aws_region.name}:${data.aws_caller_identity.aws_caller_identity.account_id}:task-definition/${aws_ecs_task_definition.airflow_webserver[0].family}-*"
    ]
  }

  statement {
    actions = [
      "ecs:DescribeTasks",
    ]

    condition {
      test     = "ArnEquals"
      variable = "ecs:cluster"
      values = [
        "arn:aws:ecs:${data.aws_region.aws_region.name}:${data.aws_caller_identity.aws_caller_identity.account_id}:cluster/${aws_ecs_cluster.notebooks.name}",
      ]
    }

    resources = [
      "arn:aws:ecs:${data.aws_region.aws_region.name}:${data.aws_caller_identity.aws_caller_identity.account_id}:task/*",
    ]
  }

  statement {
    actions = [
      "ecs:StopTask",
    ]

    condition {
      test     = "ArnEquals"
      variable = "ecs:cluster"
      values = [
        "arn:aws:ecs:${data.aws_region.aws_region.name}:${data.aws_caller_identity.aws_caller_identity.account_id}:cluster/${aws_ecs_cluster.notebooks.name}",
      ]
    }

    resources = [
      "arn:aws:ecs:${data.aws_region.aws_region.name}:${data.aws_caller_identity.aws_caller_identity.account_id}:task/*",
    ]
  }

  statement {
    actions = [
      "iam:PassRole"
    ]
    resources = [
      "${aws_iam_role.airflow_webserver_execution[count.index].arn}",
      "${aws_iam_role.airflow_webserver_task[count.index].arn}",
    ]
  }

  # For viewing logs (webserver)
  statement {
    actions = [
      "logs:GetLogEvents"
    ]

    # Should be tighter
    resources = [
      "*"
    ]
  }

  # For the tasks
  statement {
    actions = [
      "logs:CreateLogGroup"
    ]

    # Should be tighter
    resources = [
      "*"
    ]
  }

  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "*"
    ]
  }
}

resource "random_string" "airflow_secret_key" {
  length  = 64
  special = false
}
