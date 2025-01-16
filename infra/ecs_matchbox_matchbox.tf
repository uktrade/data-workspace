
locals {
  matchbox_container_vars = [for i, v in var.matchbox_instances : {
    container_image = "${aws_ecr_repository.matchbox.repository_url}:master"
    container_name  = "matchbox"
    cpu             = "${local.matchbox_container_cpu}"
    memory          = "${local.matchbox_container_memory}"
    database_uri    = "postgresql://${aws_rds_cluster.matchbox[i].master_username}:${random_string.aws_db_instance_matchbox_password[i].result}@${aws_rds_cluster.matchbox[i].endpoint}:5432/${aws_rds_cluster.matchbox[i].database_name}"
    log_group       = "${aws_cloudwatch_log_group.matchbox[0].name}"
    log_region      = "${data.aws_region.aws_region.name}"
  }]
}

resource "aws_ecs_service" "matchbox" {
  count                             = var.matchbox_on ? length(var.matchbox_instances) : 0
  name                              = "${var.prefix}-matchbox-${var.matchbox_instances[count.index]}"
  cluster                           = aws_ecs_cluster.main_cluster.id
  task_definition                   = aws_ecs_task_definition.matchbox_service[count.index].arn
  desired_count                     = 1
  launch_type                       = "FARGATE"
  deployment_maximum_percent        = 200
  platform_version                  = "1.4.0"
  health_check_grace_period_seconds = "10"

  network_configuration {
    subnets         = ["${aws_subnet.matchbox_private.*.id[0]}"]
    security_groups = ["${aws_security_group.matchbox_service[count.index].id}"]
  }
}

resource "aws_ecs_task_definition" "matchbox_service" {
  count  = var.matchbox_on ? length(var.matchbox_instances) : 0
  family = "${var.prefix}-matchbox-${var.matchbox_instances[count.index]}"
  container_definitions = templatefile(
    "${path.module}/ecs_main_matchbox_container_definitions.json",
    local.matchbox_container_vars[count.index]
  )
  execution_role_arn = aws_iam_role.matchbox_task_execution[count.index].arn
  task_role_arn      = aws_iam_role.matchbox_task[count.index].arn
  network_mode       = "awsvpc"

  cpu                      = local.matchbox_container_cpu
  memory                   = local.matchbox_container_memory
  requires_compatibilities = ["FARGATE"]
  tags                     = {}

  lifecycle {
    ignore_changes = [
      "revision",
    ]
  }
}

resource "aws_iam_role" "matchbox_task_execution" {
  count              = var.matchbox_on ? length(var.matchbox_instances) : 0
  name               = "${var.prefix}-matchbox-task-execution-${var.matchbox_instances[count.index]}"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.matchbox_task_execution_ecs_tasks_assume_role[count.index].json
}

data "aws_iam_policy_document" "matchbox_task_execution_ecs_tasks_assume_role" {
  count = var.matchbox_on ? length(var.matchbox_instances) : 0
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "matchbox_task_execution" {
  count      = var.matchbox_on ? length(var.matchbox_instances) : 0
  role       = aws_iam_role.matchbox_task_execution[count.index].name
  policy_arn = aws_iam_policy.matchbox_task_execution[count.index].arn
}

resource "aws_iam_policy" "matchbox_task_execution" {
  count  = var.matchbox_on ? length(var.matchbox_instances) : 0
  name   = "${var.prefix}-matchbox-${var.matchbox_instances[count.index]}-task-execution"
  path   = "/"
  policy = data.aws_iam_policy_document.matchbox_task_execution[count.index].json
}

data "aws_iam_policy_document" "matchbox_task_execution" {
  count = var.matchbox_on ? length(var.matchbox_instances) : 0

  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "${aws_cloudwatch_log_group.matchbox[0].arn}:*",
    ]
  }

  statement {
    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]

    resources = [
      "${aws_ecr_repository.matchbox.arn}",
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

resource "aws_iam_role" "matchbox_task" {
  count              = var.matchbox_on ? length(var.matchbox_instances) : 0
  name               = "${var.prefix}-matchbox-${var.matchbox_instances[count.index]}-task"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.matchbox_task_ecs_tasks_assume_role[count.index].json
}

data "aws_iam_policy_document" "matchbox_task_ecs_tasks_assume_role" {
  count = var.matchbox_on ? length(var.matchbox_instances) : 0
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_rds_cluster" "matchbox" {
  count                   = var.matchbox_on ? length(var.matchbox_instances) : 0
  cluster_identifier      = "${var.prefix}-matchbox-${var.matchbox_instances[count.index]}"
  engine                  = "aurora-postgresql"
  availability_zones      = var.aws_availability_zones
  database_name           = "${var.prefix_underscore}_matchbox_${var.matchbox_instances[count.index]}"
  master_username         = "${var.prefix_underscore}_matchbox_master_${var.matchbox_instances[count.index]}"
  master_password         = random_string.aws_db_instance_matchbox_password[count.index].result
  backup_retention_period = 1
  preferred_backup_window = "03:29-03:59"
  apply_immediately       = true

  vpc_security_group_ids = ["${aws_security_group.matchbox_db[count.index].id}"]
  db_subnet_group_name   = aws_db_subnet_group.matchbox[count.index].name

  final_snapshot_identifier = "${var.prefix}-matchbox-${var.matchbox_instances[count.index]}"
  copy_tags_to_snapshot     = true
}

resource "aws_rds_cluster_instance" "matchbox" {
  count              = var.matchbox_on ? 1 : 0
  identifier         = "${var.prefix}-matchbox-${var.matchbox_instances[count.index]}"
  cluster_identifier = aws_rds_cluster.matchbox[count.index].id
  engine             = aws_rds_cluster.matchbox[count.index].engine
  engine_version     = aws_rds_cluster.matchbox[count.index].engine_version
  instance_class     = var.matchbox_db_instance_class
  promotion_tier     = 1
}

resource "aws_db_subnet_group" "matchbox" {
  count      = var.matchbox_on ? 1 : 0
  name       = "${var.prefix}-matchbox"
  subnet_ids = aws_subnet.matchbox_private.*.id

  tags = {
    Name = "${var.prefix}-matchbox"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "random_string" "aws_db_instance_matchbox_password" {
  count   = var.matchbox_on ? length(var.matchbox_instances) : 0
  length  = 99
  special = false
}

resource "aws_s3_bucket" "matchbox" {
  count  = length(var.matchbox_instances)
  bucket = "${var.matchbox_artifacts_bucket}-${var.matchbox_instances[count.index]}"

  server_side_encryption_configuration {
    rule {
      bucket_key_enabled = false
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_policy" "matchbox" {
  count  = length(var.matchbox_instances)
  bucket = aws_s3_bucket.matchbox[count.index].id
  policy = data.aws_iam_policy_document.matchbox[count.index].json
}

data "aws_iam_policy_document" "matchbox" {
  count = length(var.matchbox_instances)
  statement {
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = [
      "s3:*",
    ]
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.matchbox[count.index].id}/*",
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values = [
        "false"
      ]
    }
  }
}

resource "aws_cloudwatch_log_group" "matchbox" {
  count             = var.matchbox_on ? 1 : 0
  name              = "${var.prefix}-matchbox"
  retention_in_days = "3653"
}