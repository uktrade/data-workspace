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
  container_definitions = jsonencode([
    {
      "environment" = [
        {
          "name" = "GITLAB_OMNIBUS_CONFIG",
          "value" = templatestring(
            local.gitlab_omnibus_config, {
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
        },
        {
          "name"  = "BUCKET",
          "value" = aws_s3_bucket.gitlab[count.index].id
        },
        {
          "name"  = "AWS_DEFAULT_REGION",
          "value" = aws_s3_bucket.gitlab[count.index].region
        },
        {
          "name"  = "SECRET_NAME",
          "value" = aws_secretsmanager_secret.gitlab[count.index].name
      }],
      "essential" = true,
      "image"     = "${aws_ecr_repository.gitlab.repository_url}:master",
      "logConfiguration" = {
        "logDriver" = "awslogs",
        "options" = {
          "awslogs-group"         = aws_cloudwatch_log_group.gitlab[count.index].name
          "awslogs-region"        = data.aws_region.aws_region.name,
          "awslogs-stream-prefix" = "gitlab"
        }
      },
      "networkMode"       = "awsvpc",
      "memoryReservation" = tonumber(var.gitlab_memory),
      "cpu"               = tonumber(var.gitlab_cpu),
      "mountPoints" = [
        {
          "containerPath" = "/var/opt/gitlab",
          "sourceVolume"  = "data-gitlab"
        }
      ],
      "name" = "gitlab",
      "portMappings" = [
        {
          "containerPort" = 80,
          "hostPort"      = 80,
          "protocol"      = "tcp"
        },
        {
          "containerPort" = 22,
          "hostPort"      = 22,
          "protocol"      = "tcp"
        }
      ]
    }
  ])

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

locals {
  gitlab_omnibus_config = <<-EOT
    external_url 'https://$${external_domain}'
    nginx['listen_port'] = 80
    nginx['listen_https'] = false
    letsencrypt['enable'] = false
    redis['enable'] = false
    postgresql['enable'] = false
    gitlab_rails['redis_host'] = '$${redis__host}'
    gitlab_rails['redis_port'] = $${redis__port}
    gitlab_rails['db_adapter'] = 'postgresql'
    gitlab_rails['db_encoding'] = 'utf8'
    gitlab_rails['db_host'] = '$${db__host}'
    gitlab_rails['db_port'] = $${db__port}
    gitlab_rails['db_username'] = '$${db__user}'
    gitlab_rails['db_password'] = '$${db__password}'
    gitlab_rails['db_database'] = '$${db__name}'
    gitlab_rails['uploads_object_store_enabled'] = true
    gitlab_rails['uploads_object_store_remote_directory'] = 'uploads'
    gitlab_rails['uploads_object_store_connection'] = {
      'provider' => 'AWS',
      'region' => '$${bucket__region}',
      'host' => '$${bucket__domain}',
      'use_iam_profile' => true
    }
    gitlab_rails['artifacts_enabled'] = true
    gitlab_rails['artifacts_object_store_enabled'] = true;
    gitlab_rails['artifacts_object_store_remote_directory'] = 'artifacts';
    gitlab_rails['artifacts_object_store_connection'] = {
      'provider' => 'AWS',
      'region' => '$${bucket__region}',
      'host' => '$${bucket__domain}',
      'use_iam_profile' => true
    }
    gitlab_rails['lfs_object_store_enabled'] = true
    gitlab_rails['lfs_object_store_remote_directory'] = 'lfs-objects'
    gitlab_rails['lfs_object_store_connection'] = {
      'provider' => 'AWS',
      'region' => 'eu-west-2',
      'host' => '$${bucket__domain}',
      'use_iam_profile' => true
    }
    gitlab_rails['external_diffs_enabled'] = true
    gitlab_rails['external_diffs_object_store_enabled'] = true
    gitlab_rails['external_diffs_object_store_remote_directory'] = 'external-diffs'
    gitlab_rails['external_diffs_object_store_connection'] = {
      'provider' => 'AWS',
      'region' => '$${bucket__region}',
      'host' => '$${bucket__domain}',
      'use_iam_profile' => true
    }
    #https://gitlab.com/satorix/omniauth-oauth2-generic
    gitlab_rails['omniauth_enabled'] = true
    gitlab_rails['omniauth_allow_single_sign_on'] = ['oauth2_generic']
    gitlab_rails['omniauth_auto_sign_in_with_provider'] = 'oauth2_generic'
    gitlab_rails['omniauth_block_auto_created_users'] = false
    gitlab_rails['omniauth_providers'] = [{
      'name' => 'oauth2_generic',
      'app_id' => '$${sso__id}',
      'app_secret' => '$${sso__secret}',
      'redirect_url' => 'https://$${external_domain}/auth/oauth2_generic/callback',
      'args' => {
        client_options: {
          'site' => 'https://$${sso__domain}',
          'authorize_url': '/o/authorize/',
          'token_url': '/o/token/',
          'user_info_url' => '/api/v1/user/me/'
        },
        user_response_structure: {
          root_path: [],
          id_path: ['user_id'],
        }
      }
    }]
  EOT
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
