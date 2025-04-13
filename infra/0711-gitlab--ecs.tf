resource "aws_ecs_service" "gitlab" {
  count                      = var.gitlab_on ? 1 : 0
  name                       = "${var.prefix}-gitlab"
  cluster                    = aws_ecs_cluster.main_cluster.id
  task_definition            = aws_ecs_task_definition.gitlab[count.index].arn
  desired_count              = 1
  launch_type                = "EC2"
  deployment_maximum_percent = 200
  timeouts {}

  network_configuration {
    subnets         = ["${aws_subnet.private_with_egress.*.id[0]}"]
    security_groups = ["${aws_security_group.gitlab_service[count.index].id}"]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.gitlab_80[count.index].arn
    container_port   = "80"
    container_name   = "gitlab"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.gitlab_22[count.index].arn
    container_port   = "22"
    container_name   = "gitlab"
  }

  service_registries {
    registry_arn = aws_service_discovery_service.gitlab[count.index].arn
  }

  depends_on = [
    # The target group must have been associated with the listener first
    aws_lb_listener.gitlab_443,
    aws_lb_listener.gitlab_22,
  ]
}

resource "aws_service_discovery_service" "gitlab" {
  count = var.gitlab_on ? 1 : 0
  name  = "gitlab"
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

resource "aws_ecs_task_definition" "gitlab" {
  count  = var.gitlab_on ? 1 : 0
  family = "${var.prefix}-gitlab"
  container_definitions = templatefile(
    "${path.module}/ecs_main_gitlab_container_definitions.json", {
      container_image = "${aws_ecr_repository.gitlab.repository_url}:master"
      container_name  = "gitlab"
      log_group       = "${aws_cloudwatch_log_group.gitlab[count.index].name}"
      log_region      = "${data.aws_region.aws_region.name}"

      memory = "${var.gitlab_memory}"
      cpu    = "${var.gitlab_cpu}"

      gitlab_omnibus_config = "${jsonencode(
        templatefile(
          "${path.module}/ecs_main_gitlab_container_definitions_GITLAB_OMNIBUS_CONFIG.rb", {
            external_domain = "${var.gitlab_domain}"
            db__host        = "${aws_rds_cluster.gitlab[count.index].endpoint}"
            db__name        = "${aws_rds_cluster.gitlab[count.index].database_name}"
            db__password    = "${random_string.aws_db_instance_gitlab_password.result}"
            db__port        = "${aws_rds_cluster.gitlab[count.index].port}"
            db__user        = "${aws_rds_cluster.gitlab[count.index].master_username}"

            redis__host = "${aws_elasticache_cluster.gitlab_redis[count.index].cache_nodes.0.address}"
            redis__port = "${aws_elasticache_cluster.gitlab_redis[count.index].cache_nodes.0.port}"

            bucket__region = "${aws_s3_bucket.gitlab[count.index].region}"
            bucket__domain = "${aws_s3_bucket.gitlab[count.index].bucket_regional_domain_name}"

            sso__id     = "${var.gitlab_sso_id}"
            sso__secret = "${var.gitlab_sso_secret}"
            sso__domain = "${var.gitlab_sso_domain}"
          }
        )
      )}"
      bucket        = "${aws_s3_bucket.gitlab[count.index].id}"
      bucket_region = "${aws_s3_bucket.gitlab[count.index].region}"

      secret_name = "${aws_secretsmanager_secret.gitlab[count.index].name}"
    }
  )
  execution_role_arn       = aws_iam_role.gitlab_task_execution[count.index].arn
  task_role_arn            = aws_iam_role.gitlab_task[count.index].arn
  network_mode             = "awsvpc"
  memory                   = var.gitlab_memory
  cpu                      = var.gitlab_cpu
  requires_compatibilities = ["EC2"]

  volume {
    name      = "data-gitlab"
    host_path = "/data/gitlab"
  }

  lifecycle {
    ignore_changes = [
      revision,
    ]
  }
}

resource "aws_iam_role" "gitlab_task_execution" {
  count              = var.gitlab_on ? 1 : 0
  name               = "${var.prefix}-gitlab-task-execution"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.gitlab_task_execution_ecs_tasks_assume_role[count.index].json
}

data "aws_iam_policy_document" "gitlab_task_execution_ecs_tasks_assume_role" {
  count = var.gitlab_on ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "gitlab_task_execution" {
  count      = var.gitlab_on ? 1 : 0
  role       = aws_iam_role.gitlab_task_execution[count.index].name
  policy_arn = aws_iam_policy.gitlab_task_execution[count.index].arn
}

resource "aws_iam_policy" "gitlab_task_execution" {
  count  = var.gitlab_on ? 1 : 0
  name   = "${var.prefix}-gitlab-task-execution"
  path   = "/"
  policy = data.aws_iam_policy_document.gitlab_task_execution[count.index].json
}

data "aws_iam_policy_document" "gitlab_task_execution" {
  count = var.gitlab_on ? 1 : 0
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "${aws_cloudwatch_log_group.gitlab[count.index].arn}:*",
    ]
  }

  statement {
    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]

    resources = [
      "${aws_ecr_repository.gitlab.arn}",
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

resource "aws_iam_role" "gitlab_task" {
  count              = var.gitlab_on ? 1 : 0
  name               = "${var.prefix}-gitlab-task"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.gitlab_task_ecs_tasks_assume_role[count.index].json
}

resource "aws_iam_role_policy_attachment" "gitlab_secret" {
  count      = var.gitlab_on ? 1 : 0
  role       = aws_iam_role.gitlab_task[count.index].name
  policy_arn = aws_iam_policy.gitlab_secret[count.index].arn
}

resource "aws_iam_policy" "gitlab_secret" {
  count  = var.gitlab_on ? 1 : 0
  name   = "${var.prefix}-gitlab-secret"
  path   = "/"
  policy = data.aws_iam_policy_document.gitlab_secret[count.index].json
}

data "aws_iam_policy_document" "gitlab_secret" {
  count = var.gitlab_on ? 1 : 0
  statement {
    actions = [
      "secretsmanager:GetSecretValue"
    ]

    resources = [
      "${aws_secretsmanager_secret.gitlab[count.index].arn}"
    ]
  }
}

resource "aws_iam_role_policy_attachment" "gitlab_access_gitlab_bucket" {
  count      = var.gitlab_on ? 1 : 0
  role       = aws_iam_role.gitlab_task[count.index].name
  policy_arn = aws_iam_policy.gitlab_access_uploads_bucket[count.index].arn
}

resource "aws_iam_policy" "gitlab_access_uploads_bucket" {
  count  = var.gitlab_on ? 1 : 0
  name   = "${var.prefix}-gitlab-access-gitlab-bucket"
  path   = "/"
  policy = data.aws_iam_policy_document.gitlab_access_gitlab_bucket[count.index].json
}

data "aws_iam_policy_document" "gitlab_access_gitlab_bucket" {
  count = var.gitlab_on ? 1 : 0
  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject"
    ]

    resources = [
      "${aws_s3_bucket.gitlab[count.index].arn}/*",
    ]
  }

  statement {
    actions = [
      "s3:GetBucketLocation",
      "s3:ListObjects",
    ]

    resources = [
      "${aws_s3_bucket.gitlab[count.index].arn}",
    ]
  }
}

data "aws_iam_policy_document" "gitlab_task_ecs_tasks_assume_role" {
  count = var.gitlab_on ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "gitlab_ecs" {
  count              = var.gitlab_on ? 1 : 0
  name               = "${var.prefix}-gitlab-ecs"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.gitlab_ecs_assume_role[count.index].json
}

resource "aws_iam_role_policy_attachment" "gitlab_ecs" {
  count      = var.gitlab_on ? 1 : 0
  role       = aws_iam_role.gitlab_ecs[count.index].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}

data "aws_iam_policy_document" "gitlab_ecs_assume_role" {
  count = var.gitlab_on ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}

resource "aws_secretsmanager_secret" "gitlab" {
  count = var.gitlab_on ? 1 : 0
  name  = "${var.prefix}/gitlab"
}

resource "aws_cloudwatch_log_group" "gitlab" {
  count             = var.gitlab_on ? 1 : 0
  name              = "${var.prefix}-gitlab"
  retention_in_days = "3653"
}

resource "aws_cloudwatch_log_subscription_filter" "gitlab" {
  count           = var.gitlab_on && var.cloudwatch_subscription_filter ? 1 : 0
  name            = "${var.prefix}-gitlab"
  log_group_name  = aws_cloudwatch_log_group.gitlab[count.index].name
  filter_pattern  = ""
  destination_arn = var.cloudwatch_destination_arn
}
