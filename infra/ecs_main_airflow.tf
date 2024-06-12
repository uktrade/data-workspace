resource "aws_ecs_service" "airflow" {
  count                             = var.airflow_on ? 1 : 0
  name                              = "${var.prefix}-airflow"
  cluster                           = aws_ecs_cluster.main_cluster.id
  task_definition                   = aws_ecs_task_definition.airflow_service[count.index].arn
  desired_count                     = 1
  launch_type                       = "FARGATE"
  deployment_maximum_percent        = 200
  platform_version                  = "1.4.0"
  health_check_grace_period_seconds = "10"

  network_configuration {
    subnets         = ["${aws_subnet.private_with_egress.*.id[0]}"]
    security_groups = ["${aws_security_group.airflow_service.id}"]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.airflow_8080[count.index].arn
    container_port   = "8080"
    container_name   = "airflow"
  }

  depends_on = [
    aws_lb_listener.airflow_443,
  ]
}

resource "aws_ecs_task_definition" "airflow_service" {
  count  = var.airflow_on ? 1 : 0
  family = "${var.prefix}-airflow"
  container_definitions = templatefile(
    "${path.module}/ecs_main_airflow_container_definitions.json", {
      container_image = "${aws_ecr_repository.airflow.repository_url}:master"
      container_name  = "airflow"
      log_group       = "${aws_cloudwatch_log_group.airflow[count.index].name}"
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
    }
  )
  execution_role_arn       = aws_iam_role.airflow_task_execution[count.index].arn
  task_role_arn            = aws_iam_role.airflow_task[count.index].arn
  network_mode             = "awsvpc"
  cpu                      = local.airflow_container_cpu
  memory                   = local.airflow_container_memory
  requires_compatibilities = ["FARGATE"]

  lifecycle {
    ignore_changes = [revision]
  }
}

resource "aws_ecs_service" "airflow_dag_processor" {
  count                      = var.airflow_on ? length(var.airflow_dag_processors) : 0
  name                       = "${var.prefix}-airflow-dag-processor-${var.airflow_dag_processors[count.index]}"
  cluster                    = aws_ecs_cluster.main_cluster.id
  task_definition            = aws_ecs_task_definition.airflow_dag_processor_service[count.index].arn
  desired_count              = 1
  launch_type                = "FARGATE"
  deployment_maximum_percent = 200
  platform_version           = "1.4.0"

  network_configuration {
    subnets         = ["${aws_subnet.private_with_egress.*.id[0]}"]
    security_groups = ["${aws_security_group.airflow_dag_processor_service.id}"]
  }

}

locals {
  airflow_dag_processor_container_vars = [
    for i, v in var.airflow_dag_processors : {
      container_image = "${aws_ecr_repository.airflow_dag_processor.repository_url}:master"
      container_name  = "airflow-dag-processor"
      log_group       = "${aws_cloudwatch_log_group.airflow_dag_processor[i].name}"
      log_region      = "${data.aws_region.aws_region.name}"
      cpu             = "${local.airflow_container_cpu}"
      memory          = "${local.airflow_container_memory}"

      db_host     = "${aws_rds_cluster.airflow[0].endpoint}"
      db_name     = "${aws_rds_cluster.airflow[0].database_name}"
      db_password = "${random_string.aws_db_instance_airflow_password.result}"
      db_port     = "${aws_rds_cluster.airflow[0].port}"
      db_user     = "${aws_rds_cluster.airflow[0].master_username}"
      secret_key  = "${random_string.airflow_secret_key.result}"

      datasets_db_host     = "${aws_rds_cluster.datasets.endpoint}"
      datasets_db_name     = "${aws_rds_cluster.datasets.database_name}"
      datasets_db_password = "${random_string.aws_rds_cluster_instance_datasets_password.result}"
      datasets_db_port     = "${aws_rds_cluster.datasets.port}"
      datasets_db_user     = "${var.datasets_rds_cluster_master_username}"

      sentry_dsn         = "${var.sentry_notebooks_dsn}"
      sentry_environment = "${var.sentry_environment}"

      team = "${v}"
    }
  ]
}

resource "aws_ecs_task_definition" "airflow_dag_processor_service" {
  count  = var.airflow_on ? length(var.airflow_dag_processors) : 0
  family = "${var.prefix}-airflow-dag-processor-${var.airflow_dag_processors[count.index]}"
  container_definitions = templatefile(
    "${path.module}/ecs_main_airflow_dag_processor_container_definitions.json",
    local.airflow_dag_processor_container_vars[count.index]
  )
  execution_role_arn       = aws_iam_role.airflow_dag_processor_task_execution[count.index].arn
  task_role_arn            = aws_iam_role.airflow_dag_processor_task[count.index].arn
  network_mode             = "awsvpc"
  cpu                      = local.airflow_container_cpu
  memory                   = local.airflow_container_memory
  requires_compatibilities = ["FARGATE"]

  lifecycle {
    ignore_changes = [revision]
  }
}

resource "aws_cloudwatch_log_group" "airflow_dag_processor" {
  count             = var.airflow_on ? length(var.airflow_dag_processors) : 0
  name              = "${var.prefix}-airflow-dag-processor-${var.airflow_dag_processors[count.index]}"
  retention_in_days = "3653"
}

resource "aws_cloudwatch_log_subscription_filter" "airflow_dag_processor" {
  count           = var.cloudwatch_subscription_filter && var.airflow_on ? length(var.airflow_dag_processors) : 0
  name            = "${var.prefix}-airflow-dag-processor-${var.airflow_dag_processors[count.index]}"
  log_group_name  = aws_cloudwatch_log_group.airflow_dag_processor[count.index].name
  filter_pattern  = ""
  destination_arn = var.cloudwatch_destination_arn
}

resource "aws_cloudwatch_log_group" "airflow" {
  count             = var.airflow_on ? 1 : 0
  name              = "${var.prefix}-airflow"
  retention_in_days = "3653"
}

resource "aws_cloudwatch_log_subscription_filter" "airflow" {
  count           = var.cloudwatch_subscription_filter && var.airflow_on ? 1 : 0
  name            = "${var.prefix}-airflow"
  log_group_name  = aws_cloudwatch_log_group.airflow[count.index].name
  filter_pattern  = ""
  destination_arn = var.cloudwatch_destination_arn
}

#################

resource "aws_iam_role" "airflow_dag_processor_task_execution" {
  count              = var.airflow_on ? length(var.airflow_dag_processors) : 0
  name               = "${var.prefix}-airflow-dag-processor-${var.airflow_dag_processors[count.index]}"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.airflow_dag_processor_task_execution_ecs_tasks_assume_role[count.index].json
}

data "aws_iam_policy_document" "airflow_dag_processor_task_execution_ecs_tasks_assume_role" {
  count = var.airflow_on ? length(var.airflow_dag_processors) : 0
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "airflow_dag_processor_task_execution" {
  count      = var.airflow_on ? length(var.airflow_dag_processors) : 0
  role       = aws_iam_role.airflow_dag_processor_task_execution[count.index].name
  policy_arn = aws_iam_policy.airflow_dag_processor_task_execution[count.index].arn
}

resource "aws_iam_policy" "airflow_dag_processor_task_execution" {
  count  = var.airflow_on ? length(var.airflow_dag_processors) : 0
  name   = "${var.prefix}-airflow-dag-processor-${var.airflow_dag_processors[count.index]}"
  path   = "/"
  policy = data.aws_iam_policy_document.airflow_dag_processor_task_execution[count.index].json
}

data "aws_iam_policy_document" "airflow_dag_processor_task_execution" {
  count = var.airflow_on ? length(var.airflow_dag_processors) : 0
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "${aws_cloudwatch_log_group.airflow_dag_processor[count.index].arn}:*",
    ]
  }

  statement {
    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]

    resources = [
      "${aws_ecr_repository.airflow_dag_processor.arn}",
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

resource "aws_iam_role" "airflow_dag_processor_task" {
  count              = var.airflow_on ? length(var.airflow_dag_processors) : 0
  name               = "${var.prefix}-airflow-dp-task-${var.airflow_dag_processors[count.index]}"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.airflow_dag_processor_task_ecs_tasks_assume_role[count.index].json
}

data "aws_iam_policy_document" "airflow_dag_processor_task_ecs_tasks_assume_role" {
  count = var.airflow_on ? length(var.airflow_dag_processors) : 0
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

#################

resource "aws_iam_role" "airflow_task_execution" {
  count              = var.airflow_on ? 1 : 0
  name               = "${var.prefix}-airflow-task-execution"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.airflow_task_execution_ecs_tasks_assume_role[count.index].json
}

data "aws_iam_policy_document" "airflow_task_execution_ecs_tasks_assume_role" {
  count = var.airflow_on ? 1 : 0
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "airflow_task_execution" {
  count      = var.airflow_on ? 1 : 0
  role       = aws_iam_role.airflow_task_execution[count.index].name
  policy_arn = aws_iam_policy.airflow_task_execution[count.index].arn
}

resource "aws_iam_policy" "airflow_task_execution" {
  count  = var.airflow_on ? 1 : 0
  name   = "${var.prefix}-airflow-task-execution"
  path   = "/"
  policy = data.aws_iam_policy_document.airflow_task_execution[count.index].json
}

data "aws_iam_policy_document" "airflow_task_execution" {
  count = var.airflow_on ? 1 : 0
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "${aws_cloudwatch_log_group.airflow[count.index].arn}:*",
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

resource "aws_iam_role" "airflow_task" {
  count              = var.airflow_on ? 1 : 0
  name               = "${var.prefix}-airflow-task"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.airflow_task_ecs_tasks_assume_role[count.index].json
}

data "aws_iam_policy_document" "airflow_task_ecs_tasks_assume_role" {
  count = var.airflow_on ? 1 : 0
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_lb" "airflow" {
  count                      = var.airflow_on ? 1 : 0
  name                       = "${var.prefix}-airflow"
  load_balancer_type         = "application"
  internal                   = false
  security_groups            = ["${aws_security_group.airflow_lb.id}"]
  subnets                    = aws_subnet.public.*.id
  enable_deletion_protection = true
}

resource "aws_lb_listener" "airflow_443" {
  count             = var.airflow_on ? 1 : 0
  load_balancer_arn = aws_lb.airflow[count.index].arn
  port              = "443"
  protocol          = "HTTPS"

  ssl_policy      = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn = aws_acm_certificate_validation.airflow[count.index].certificate_arn

  default_action {
    target_group_arn = aws_lb_target_group.airflow_8080[count.index].arn
    type             = "forward"
  }
}

resource "aws_lb_target_group" "airflow_8080" {
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

resource "aws_rds_cluster" "airflow" {
  count                   = var.airflow_on ? 1 : 0
  cluster_identifier      = "${var.prefix}-airflow"
  engine                  = "aurora-postgresql"
  availability_zones      = var.aws_availability_zones
  database_name           = "${var.prefix_underscore}_airflow"
  master_username         = "${var.prefix_underscore}_airflow_master"
  master_password         = random_string.aws_db_instance_airflow_password.result
  backup_retention_period = 31
  preferred_backup_window = "03:29-03:59"
  apply_immediately       = true

  vpc_security_group_ids = ["${aws_security_group.airflow_db.id}"]
  db_subnet_group_name   = aws_db_subnet_group.airflow[count.index].name

  final_snapshot_identifier = "${var.prefix}-airflow"

  copy_tags_to_snapshot          = true
  enable_global_write_forwarding = false
}

resource "aws_rds_cluster_instance" "airflow" {
  count              = var.airflow_on ? 1 : 0
  identifier         = "${var.prefix}-airflow"
  cluster_identifier = aws_rds_cluster.airflow[count.index].id
  engine             = aws_rds_cluster.airflow[count.index].engine
  engine_version     = aws_rds_cluster.airflow[count.index].engine_version
  instance_class     = var.airflow_db_instance_class
  promotion_tier     = 1
}

resource "aws_db_subnet_group" "airflow" {
  count      = var.airflow_on ? 1 : 0
  name       = "${var.prefix}-airflow"
  subnet_ids = aws_subnet.private_with_egress.*.id

  tags = {
    Name = "${var.prefix}-airflow"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "random_string" "aws_db_instance_airflow_password" {
  length  = 99
  special = false
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

resource "random_string" "airflow_secret_key" {
  length  = 64
  special = false
}
