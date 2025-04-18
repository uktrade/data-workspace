resource "aws_ecs_service" "mlflow" {
  count                             = var.mlflow_on ? length(var.mlflow_instances) : 0
  name                              = "${var.prefix}-mlflow-${var.mlflow_instances[count.index]}"
  cluster                           = aws_ecs_cluster.main_cluster.id
  task_definition                   = aws_ecs_task_definition.mlflow_service[count.index].arn
  desired_count                     = 1
  launch_type                       = "FARGATE"
  deployment_maximum_percent        = 200
  platform_version                  = "1.4.0"
  health_check_grace_period_seconds = "10"

  network_configuration {
    subnets         = ["${aws_subnet.private_without_egress.*.id[0]}"]
    security_groups = ["${aws_security_group.mlflow_service[count.index].id}"]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.mlflow[count.index].arn
    container_port   = local.mlflow_port
    container_name   = "mlflow"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.mlflow_dataflow[count.index].arn
    container_port   = local.mlflow_port
    container_name   = "mlflow"
  }

  service_registries {
    registry_arn = aws_service_discovery_service.mlflow[count.index].arn
  }

  depends_on = [
    aws_lb_listener.mlflow,
  ]
}

resource "aws_service_discovery_service" "mlflow" {
  count = var.mlflow_on ? length(var.mlflow_instances) : 0
  name  = "mlflow--${var.mlflow_instances_long[count.index]}"
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

resource "aws_ecs_task_definition" "mlflow_service" {
  count  = var.mlflow_on ? length(var.mlflow_instances) : 0
  family = "${var.prefix}-mlflow-${var.mlflow_instances[count.index]}"
  container_definitions = jsonencode([
    {
      "environment" = [
        {
          "name"  = "ARTIFACT_BUCKET_NAME",
          "value" = aws_s3_bucket.mlflow[count.index].bucket
        },
        {
          # The public key is already JSON-encoded from a previous version of the Terraform where
          # it was put directly into the JSON
          "name"  = "JWT_PUBLIC_KEY",
          "value" = jsondecode("\"${var.jwt_public_key}\"")
        },
        {
          "name"  = "MLFLOW_HOSTNAME",
          "value" = "http://mlflow--${var.mlflow_instances_long[count.index]}.${var.admin_domain}"
        },
        {
          "name"  = "DATABASE_URI",
          "value" = "postgresql://${aws_rds_cluster.mlflow[count.index].master_username}:${random_string.aws_db_instance_mlflow_password[count.index].result}@${aws_rds_cluster.mlflow[count.index].endpoint}:5432/${aws_rds_cluster.mlflow[count.index].database_name}"
        },
        {
          "name"  = "PROXY_PORT",
          "value" = tostring(local.mlflow_port)
        },
        {
          "name"  = "AWS_DEFAULT_REGION",
          "value" = "eu-west-2"
        }
      ],
      "essential" = true,
      "image"     = "${aws_ecr_repository.mlflow.repository_url}:master",
      "logConfiguration" = {
        "logDriver" = "awslogs",
        "options" = {
          "awslogs-group"         = aws_cloudwatch_log_group.mlflow[count.index].name,
          "awslogs-region"        = data.aws_region.aws_region.name,
          "awslogs-stream-prefix" = "mlflow"
        }
      },
      "networkMode"       = "awsvpc",
      "memoryReservation" = local.mlflow_container_memory,
      "cpu"               = local.mlflow_container_cpu,
      "mountPoints"       = [],
      "name"              = "mlflow",
      "portMappings" = [{
        "containerPort" = local.mlflow_port,
        "hostPort"      = local.mlflow_port,
        "protocol"      = "tcp"
      }]
    }
  ])

  execution_role_arn       = aws_iam_role.mlflow_task_execution[count.index].arn
  task_role_arn            = aws_iam_role.mlflow_task[count.index].arn
  network_mode             = "awsvpc"
  cpu                      = local.mlflow_container_cpu
  memory                   = local.mlflow_container_memory
  requires_compatibilities = ["FARGATE"]
  tags                     = {}

  lifecycle {
    ignore_changes = [
      revision,
    ]
  }
}

resource "aws_cloudwatch_log_group" "mlflow" {
  count             = var.mlflow_on ? length(var.mlflow_instances) : 0
  name              = "${var.prefix}-mlflow-${var.mlflow_instances[count.index]}"
  retention_in_days = "3653"
}

resource "aws_iam_role" "mlflow_task_execution" {
  count              = var.mlflow_on ? length(var.mlflow_instances) : 0
  name               = "${var.prefix}-mlflow-task-execution-${var.mlflow_instances[count.index]}"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.mlflow_task_execution_ecs_tasks_assume_role[count.index].json
}

data "aws_iam_policy_document" "mlflow_task_execution_ecs_tasks_assume_role" {
  count = var.mlflow_on ? length(var.mlflow_instances) : 0
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "mlflow_task_execution" {
  count      = var.mlflow_on ? length(var.mlflow_instances) : 0
  role       = aws_iam_role.mlflow_task_execution[count.index].name
  policy_arn = aws_iam_policy.mlflow_task_execution[count.index].arn
}

resource "aws_iam_policy" "mlflow_task_execution" {
  count  = var.mlflow_on ? length(var.mlflow_instances) : 0
  name   = "${var.prefix}-mlflow-${var.mlflow_instances[count.index]}-task-execution"
  path   = "/"
  policy = data.aws_iam_policy_document.mlflow_task_execution[count.index].json
}

data "aws_iam_policy_document" "mlflow_task_execution" {
  count = var.mlflow_on ? length(var.mlflow_instances) : 0
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "${aws_cloudwatch_log_group.mlflow[count.index].arn}:*",
    ]
  }

  statement {
    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]

    resources = [
      "${aws_ecr_repository.mlflow.arn}",
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

resource "aws_iam_role" "mlflow_task" {
  count              = var.mlflow_on ? length(var.mlflow_instances) : 0
  name               = "${var.prefix}-mlflow-${var.mlflow_instances[count.index]}-task"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.mlflow_task_ecs_tasks_assume_role[count.index].json
}

data "aws_iam_policy_document" "mlflow_task_ecs_tasks_assume_role" {
  count = var.mlflow_on ? length(var.mlflow_instances) : 0
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "mlflow_access_artifacts_bucket" {
  count      = var.mlflow_on ? length(var.mlflow_instances) : 0
  role       = aws_iam_role.mlflow_task[count.index].name
  policy_arn = aws_iam_policy.mlflow_access_artifacts_bucket[count.index].arn
}

resource "aws_iam_policy" "mlflow_access_artifacts_bucket" {
  count  = var.mlflow_on ? length(var.mlflow_instances) : 0
  name   = "${var.prefix}-mlflow-${var.mlflow_instances[count.index]}-access-artifacts-bucket"
  path   = "/"
  policy = data.aws_iam_policy_document.mlflow_access_artifacts_bucket[count.index].json
}


data "aws_iam_policy_document" "mlflow_access_artifacts_bucket" {
  count = var.mlflow_on ? length(var.mlflow_instances) : 0
  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject"
    ]

    resources = [
      "${aws_s3_bucket.mlflow[count.index].arn}/*",
    ]
  }

  statement {
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
    ]

    resources = [
      "${aws_s3_bucket.mlflow[count.index].arn}",
    ]
  }
}

resource "aws_lb" "mlflow" {
  count                            = var.mlflow_on ? length(var.mlflow_instances) : 0
  name                             = "${var.prefix}-mf-${var.mlflow_instances[count.index]}"
  load_balancer_type               = "network"
  internal                         = true
  enable_cross_zone_load_balancing = true
  enable_deletion_protection       = true

  subnet_mapping {
    subnet_id            = aws_subnet.private_without_egress.*.id[0]
    private_ipv4_address = cidrhost("${aws_subnet.private_without_egress.*.cidr_block[0]}", 7 + count.index)
  }
}

resource "aws_lb_listener" "mlflow" {
  count             = var.mlflow_on ? length(var.mlflow_instances) : 0
  load_balancer_arn = aws_lb.mlflow[count.index].arn
  port              = local.mlflow_port
  protocol          = "TCP"

  default_action {
    target_group_arn = aws_lb_target_group.mlflow[count.index].arn
    type             = "forward"
  }
}

resource "aws_lb_target_group" "mlflow" {
  count              = var.mlflow_on ? length(var.mlflow_instances) : 0
  name_prefix        = "f${var.mlflow_instances[count.index]}-"
  port               = local.mlflow_port
  vpc_id             = aws_vpc.notebooks.id
  target_type        = "ip"
  protocol           = "TCP"
  preserve_client_ip = false

  health_check {
    protocol            = "HTTP"
    interval            = 10
    healthy_threshold   = 5
    unhealthy_threshold = 5
    path                = "/healthcheck"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb" "mlflow_dataflow" {
  count                            = var.mlflow_on ? length(var.mlflow_instances) : 0
  name                             = "${var.prefix}-mfdf-${var.mlflow_instances[count.index]}"
  load_balancer_type               = "network"
  internal                         = true
  enable_cross_zone_load_balancing = true
  enable_deletion_protection       = true

  subnet_mapping {
    subnet_id            = aws_subnet.datasets.*.id[0]
    private_ipv4_address = cidrhost("${aws_subnet.datasets.*.cidr_block[0]}", 7 + count.index)
  }
}

resource "aws_lb_listener" "mlflow_dataflow" {
  count             = var.mlflow_on ? length(var.mlflow_instances) : 0
  load_balancer_arn = aws_lb.mlflow_dataflow[count.index].arn
  port              = local.mlflow_port
  protocol          = "TCP"

  default_action {
    target_group_arn = aws_lb_target_group.mlflow_dataflow[count.index].arn
    type             = "forward"
  }
}

resource "aws_lb_target_group" "mlflow_dataflow" {
  count              = var.mlflow_on ? length(var.mlflow_instances) : 0
  name_prefix        = "df${var.mlflow_instances[count.index]}-"
  port               = local.mlflow_port
  vpc_id             = aws_vpc.datasets.id
  target_type        = "ip"
  protocol           = "TCP"
  preserve_client_ip = false

  health_check {
    protocol            = "HTTP"
    interval            = 10
    healthy_threshold   = 5
    unhealthy_threshold = 5

    path = "/healthcheck"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role" "mlflow_ecs" {
  count              = var.mlflow_on ? length(var.mlflow_instances) : 0
  name               = "${var.prefix}-mlflow-${var.mlflow_instances[count.index]}-ecs"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.mlflow_ecs_assume_role[count.index].json
}

resource "aws_iam_role_policy_attachment" "mlflow_ecs" {
  count      = var.mlflow_on ? length(var.mlflow_instances) : 0
  role       = aws_iam_role.mlflow_ecs[count.index].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}

data "aws_iam_policy_document" "mlflow_ecs_assume_role" {
  count = var.mlflow_on ? length(var.mlflow_instances) : 0
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}

resource "aws_rds_cluster" "mlflow" {
  count                   = var.mlflow_on ? length(var.mlflow_instances) : 0
  cluster_identifier      = "${var.prefix}-mlflow-${var.mlflow_instances[count.index]}"
  engine                  = "aurora-postgresql"
  availability_zones      = var.aws_availability_zones
  database_name           = "${var.prefix_underscore}_mlflow_${var.mlflow_instances[count.index]}"
  master_username         = "${var.prefix_underscore}_mlflow_master_${var.mlflow_instances[count.index]}"
  master_password         = random_string.aws_db_instance_mlflow_password[count.index].result
  backup_retention_period = 31
  preferred_backup_window = "03:29-03:59"
  apply_immediately       = true

  vpc_security_group_ids = ["${aws_security_group.mlflow_db[count.index].id}"]
  db_subnet_group_name   = aws_db_subnet_group.mlflow[count.index].name

  final_snapshot_identifier = "${var.prefix}-mlflow-${var.mlflow_instances[count.index]}"
  copy_tags_to_snapshot     = true
}

resource "aws_rds_cluster_instance" "mlflow" {
  count              = var.mlflow_on ? length(var.mlflow_instances) : 0
  identifier         = "${var.prefix}-mlflow-${var.mlflow_instances[count.index]}"
  cluster_identifier = aws_rds_cluster.mlflow[count.index].id
  engine             = aws_rds_cluster.mlflow[count.index].engine
  engine_version     = aws_rds_cluster.mlflow[count.index].engine_version
  instance_class     = var.mlflow_db_instance_class
  promotion_tier     = 1
}

resource "aws_db_subnet_group" "mlflow" {
  count      = var.mlflow_on ? length(var.mlflow_instances) : 0
  name       = "${var.prefix}-mlflow-${var.mlflow_instances[count.index]}"
  subnet_ids = aws_subnet.private_without_egress.*.id

  tags = {
    Name = "${var.prefix}-mlflow-${var.mlflow_instances[count.index]}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "random_string" "aws_db_instance_mlflow_password" {
  count   = var.mlflow_on ? length(var.mlflow_instances) : 0
  length  = 99
  special = false
}
