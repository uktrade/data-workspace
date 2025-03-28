// We only ever deploy tagged images, so all ECR repos have a lifecycle policy to delete untagged
// images.
//
// Some repos also expire certain tagged images because they are either kaniko-generated cached
// layers, or no-longer deployed images

resource "aws_ecr_repository" "user_provided" {
  name = "${var.prefix}-user-provided"
}

resource "aws_ecr_lifecycle_policy" "user_provided_expire_untagged_after_one_day" {
  repository = aws_ecr_repository.user_provided.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_preview_and_untagged_after_one_day.json
}

resource "aws_ecr_repository" "admin" {
  name = "${var.prefix}-admin"
}

resource "aws_ecr_lifecycle_policy" "admin_keep_last_five_releases" {
  repository = aws_ecr_repository.admin.name
  policy     = data.aws_ecr_lifecycle_policy_document.keep_last_five_releases.json
}

resource "aws_ecr_repository" "jupyterlab_python" {
  name = "${var.prefix}-jupyterlab-python"
}

resource "aws_ecr_lifecycle_policy" "jupyterlab_python_expire_non_master_non_latest_after_one_day" {
  repository = aws_ecr_repository.jupyterlab_python.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_non_master_non_latest_after_one_day.json
}

resource "aws_ecr_repository" "rstudio" {
  name = "${var.prefix}-rstudio"
}

resource "aws_ecr_lifecycle_policy" "rstudio_expire_untagged_after_one_day" {
  repository = aws_ecr_repository.rstudio.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_untagged_after_one_day.json
}

resource "aws_ecr_repository" "rstudio_rv4" {
  name = "${var.prefix}-rstudio-rv4"
}

resource "aws_ecr_lifecycle_policy" "rstudio_rv4_expire_non_master_non_latest_after_one_day" {
  repository = aws_ecr_repository.rstudio_rv4.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_non_master_non_latest_after_one_day.json
}

resource "aws_ecr_repository" "pgadmin" {
  name = "${var.prefix}-pgadmin"
}

resource "aws_ecr_lifecycle_policy" "pgadmin_expire_non_master_non_latest_after_one_day" {
  repository = aws_ecr_repository.pgadmin.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_non_master_non_latest_after_one_day.json
}

resource "aws_ecr_repository" "remotedesktop" {
  name = "${var.prefix}-remotedesktop"
}

resource "aws_ecr_lifecycle_policy" "remotedesktop_rv4_expire_non_master_non_latest_after_one_day" {
  repository = aws_ecr_repository.remotedesktop.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_non_master_non_latest_after_one_day.json
}

resource "aws_ecr_repository" "theia" {
  name = "${var.prefix}-theia"
}

resource "aws_ecr_lifecycle_policy" "theia_expire_non_master_non_latest_after_one_day" {
  repository = aws_ecr_repository.theia.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_non_master_non_latest_after_one_day.json
}

resource "aws_ecr_repository" "vscode" {
  name = "${var.prefix}-vscode"
}

resource "aws_ecr_lifecycle_policy" "vscode_expire_untagged_after_one_day" {
  repository = aws_ecr_repository.vscode.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_untagged_after_one_day.json
}

resource "aws_ecr_repository" "s3sync" {
  name = "${var.prefix}-s3sync"
}

resource "aws_ecr_lifecycle_policy" "s3sync_expire_non_master_non_latest_after_one_day" {
  repository = aws_ecr_repository.s3sync.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_non_master_non_latest_after_one_day.json
}

resource "aws_ecr_repository" "metrics" {
  name = "${var.prefix}-metrics"
}

resource "aws_ecr_lifecycle_policy" "metrics_expire_non_master_non_latest_after_one_day" {
  repository = aws_ecr_repository.metrics.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_non_master_non_latest_after_one_day.json
}

resource "aws_ecr_repository" "sentryproxy" {
  name = "${var.prefix}-sentryproxy"
}


resource "aws_ecr_lifecycle_policy" "sentryproxy_expire_untagged_after_one_day" {
  repository = aws_ecr_repository.sentryproxy.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_untagged_after_one_day.json
}

resource "aws_ecr_repository" "dns_rewrite_proxy" {
  name = "${var.prefix}-dns-rewrite-proxy"
}

resource "aws_ecr_lifecycle_policy" "dns_rewrite_proxy_expire_untagged_after_one_day" {
  repository = aws_ecr_repository.dns_rewrite_proxy.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_untagged_after_one_day.json
}

resource "aws_ecr_repository" "healthcheck" {
  name = "${var.prefix}-healthcheck"
}

resource "aws_ecr_lifecycle_policy" "healthcheck_expire_untagged_after_one_day" {
  repository = aws_ecr_repository.healthcheck.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_untagged_after_one_day.json
}

resource "aws_ecr_repository" "prometheus" {
  name = "${var.prefix}-prometheus"
}

resource "aws_ecr_lifecycle_policy" "prometheus_expire_untagged_after_one_day" {
  repository = aws_ecr_repository.prometheus.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_untagged_after_one_day.json
}

resource "aws_ecr_repository" "gitlab" {
  name = "${var.prefix}-gitlab"
}

resource "aws_ecr_lifecycle_policy" "gitlab_expire_untagged_after_one_day" {
  repository = aws_ecr_repository.gitlab.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_untagged_after_one_day.json
}

resource "aws_ecr_repository" "visualisation_base" {
  name = "${var.prefix}-visualisation-base"
}

resource "aws_ecr_lifecycle_policy" "visualisation_base_expire_old_after_one_day" {
  repository = aws_ecr_repository.visualisation_base.name
  policy     = data.aws_ecr_lifecycle_policy_document.visualisation_base_expire_old_after_one_day.json
}

resource "aws_ecr_repository" "mirrors_sync" {
  name = "${var.prefix}-mirrors-sync"
}

resource "aws_ecr_lifecycle_policy" "mirrors_sync_expire_untagged_after_one_day" {
  repository = aws_ecr_repository.mirrors_sync.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_untagged_after_one_day.json
}

resource "aws_ecr_repository" "mirrors_sync_cran_binary" {
  name = "${var.prefix}-mirrors-sync-cran-binary"
}

resource "aws_ecr_lifecycle_policy" "mirrors_sync_cran_binary_expire_untagged_after_one_day" {
  repository = aws_ecr_repository.mirrors_sync_cran_binary.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_untagged_after_one_day.json
}

resource "aws_ecr_repository" "mirrors_sync_cran_binary_rv4" {
  name = "${var.prefix}-mirrors-sync-cran-binary-rv4"
}

resource "aws_ecr_lifecycle_policy" "mirrors_sync_cran_binary_rv4_expire_non_master_non_latest_after_one_day" {
  repository = aws_ecr_repository.mirrors_sync_cran_binary_rv4.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_non_master_non_latest_after_one_day.json
}

resource "aws_ecr_repository" "superset" {
  name = "${var.prefix}-superset"
}

resource "aws_ecr_lifecycle_policy" "superset_expire_untagged_after_one_day" {
  repository = aws_ecr_repository.superset.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_untagged_after_one_day.json
}

resource "aws_ecr_repository" "airflow" {
  name = "${var.prefix}-airflow"
}

resource "aws_ecr_lifecycle_policy" "airflow_expire_untagged_after_one_day" {
  repository = aws_ecr_repository.airflow.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_untagged_after_one_day.json
}

resource "aws_ecr_repository" "flower" {
  name = "${var.prefix}-flower"
}

resource "aws_ecr_lifecycle_policy" "flower_expire_untagged_after_one_day" {
  repository = aws_ecr_repository.flower.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_untagged_after_one_day.json
}

resource "aws_ecr_repository" "mlflow" {
  name = "${var.prefix}-mlflow"
}

resource "aws_ecr_lifecycle_policy" "mlflow_expire_untagged_after_one_day" {
  repository = aws_ecr_repository.mlflow.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_untagged_after_one_day.json
}

resource "aws_ecr_repository" "arango" {
  count = var.arango_on ? 1 : 0
  name  = "${var.prefix}-arango"
}

resource "aws_ecr_repository" "matchbox" {
  count = var.matchbox_on ? 1 : 0
  name  = "${var.prefix}-matchbox"
}

resource "aws_ecr_repository" "datadog" {
  name = "${var.prefix}-datadog"
}

resource "aws_ecr_lifecycle_policy" "datadog_expire_untagged_after_one_day" {
  repository = aws_ecr_repository.datadog.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_untagged_after_one_day.json
}

resource "aws_ecr_lifecycle_policy" "arango_expire_untagged_after_one_day" {
  count      = var.arango_on ? 1 : 0
  repository = aws_ecr_repository.arango[0].name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_untagged_after_one_day.json
}

data "aws_ecr_lifecycle_policy_document" "expire_untagged_after_one_day" {
  rule {
    priority = 1
    selection {
      tag_status   = "untagged"
      count_type   = "sinceImagePushed"
      count_unit   = "days"
      count_number = 1
    }
  }
}

data "aws_ecr_lifecycle_policy_document" "expire_preview_and_untagged_after_one_day" {
  # Match *--prod images, but expire them in 1000 years...
  rule {
    priority = 1
    selection {
      tag_status       = "tagged"
      tag_pattern_list = ["*--prod"]
      count_type       = "sinceImagePushed"
      count_unit       = "days"
      count_number     = 365000
    }
  }
  # ... and images that don't match *--prod, but have "*--*" are "preview" and we expire them 1 day
  # after they have been pushed
  rule {
    priority = 2
    selection {
      tag_status       = "tagged"
      tag_pattern_list = ["*--*"]
      count_type       = "sinceImagePushed"
      count_unit       = "days"
      count_number     = 1
    }
  }
  # ... and just in case we somehow end up with untagged images, expire them after 1 day as well
  rule {
    priority = 3
    selection {
      tag_status   = "untagged"
      count_type   = "sinceImagePushed"
      count_unit   = "days"
      count_number = 1
    }
  }
}

data "aws_ecr_lifecycle_policy_document" "visualisation_base_expire_old_after_one_day" {
  # Match tagged python, but expire them in 1000 years...
  rule {
    priority = 1
    selection {
      tag_status       = "tagged"
      tag_pattern_list = ["python"]
      count_type       = "sinceImagePushed"
      count_unit       = "days"
      count_number     = 365000
    }
  }
  # otherwise match tagged rv4, but expire them in 1000 years...
  rule {
    priority = 2
    selection {
      tag_status       = "tagged"
      tag_pattern_list = ["rv4"]
      count_type       = "sinceImagePushed"
      count_unit       = "days"
      count_number     = 365000
    }
  }
  # ... and images that don't match python or rv4, but have a tag, are cached layers
  rule {
    priority = 3
    selection {
      tag_status       = "tagged"
      tag_pattern_list = ["*"]
      count_type       = "sinceImagePushed"
      count_unit       = "days"
      count_number     = 1
    }
  }
  # ... and for when we end up with untagged images, expire them after 1 day as well
  rule {
    priority = 4
    selection {
      tag_status   = "untagged"
      count_type   = "sinceImagePushed"
      count_unit   = "days"
      count_number = 1
    }
  }
}

data "aws_ecr_lifecycle_policy_document" "expire_non_master_non_latest_after_one_day" {
  # Match tagged master, but expire them in 1000 years...
  rule {
    priority = 1
    selection {
      tag_status       = "tagged"
      tag_pattern_list = ["master"]
      count_type       = "sinceImagePushed"
      count_unit       = "days"
      count_number     = 365000
    }
  }
  # otherwise match tagged latest, but expire them in 1000 years...
  rule {
    priority = 2
    selection {
      tag_status       = "tagged"
      tag_pattern_list = ["latest"]
      count_type       = "sinceImagePushed"
      count_unit       = "days"
      count_number     = 365000
    }
  }
  # ... and images that don't match python or rv4, but have a tag, are cached layers
  rule {
    priority = 3
    selection {
      tag_status       = "tagged"
      tag_pattern_list = ["*"]
      count_type       = "sinceImagePushed"
      count_unit       = "days"
      count_number     = 1
    }
  }
  # ... and for when we end up with untagged images, expire them after 1 day as well
  rule {
    priority = 4
    selection {
      tag_status   = "untagged"
      count_type   = "sinceImagePushed"
      count_unit   = "days"
      count_number = 1
    }
  }
}

data "aws_ecr_lifecycle_policy_document" "keep_last_five_releases" {
  # always keep five images that fit semantic versioning pattern
  rule {
    priority = 1
    selection {
      tag_status       = "tagged"
      tag_pattern_list = ["v*.*.*"]
      count_type       = "imageCountMoreThan"
      count_number     = 5
    }
  }
  # keep five other images (from PR merge builds etc)
  rule {
    priority = 2
    selection {
      tag_status       = "tagged"
      tag_pattern_list = ["*"]
      count_type       = "imageCountMoreThan"
      count_number     = 5
    }
  }
  # ... and just in case we somehow end up with untagged images, expire them after 1 day
  rule {
    priority = 3
    selection {
      tag_status   = "untagged"
      count_type   = "sinceImagePushed"
      count_unit   = "days"
      count_number = 1
    }
  }
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.aws_region.name}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  security_group_ids = ["${aws_security_group.ecr_dkr.id}"]
  subnet_ids         = ["${aws_subnet.private_with_egress.*.id[0]}"]

  policy = data.aws_iam_policy_document.aws_vpc_endpoint_ecr.json

  timeouts {}
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.aws_region.name}.ecr.api"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  security_group_ids = ["${aws_security_group.ecr_api.id}"]
  subnet_ids         = ["${aws_subnet.private_with_egress.*.id[0]}"]

  policy = data.aws_iam_policy_document.aws_vpc_endpoint_ecr.json

  timeouts {}
}

data "aws_iam_policy_document" "aws_vpc_endpoint_ecr" {
  # Contains policies for both ECR and DKR endpoints, as recommended

  statement {
    principals {
      type        = "AWS"
      identifiers = ["${aws_iam_role.admin_task.arn}"]
    }

    actions = [
      "ecr:DescribeImages",
      "ecr:BatchGetImage",
      "ecr:PutImage",
    ]

    resources = [
      "${aws_ecr_repository.user_provided.arn}",
    ]
  }

  statement {
    principals {
      type        = "AWS"
      identifiers = ["${aws_iam_role.admin_task.arn}"]
    }

    actions = [
      "ecs:DescribeTaskDefinition",
    ]

    resources = [
      # ECS doesn't provide more-specific permission for DescribeTaskDefinition
      "*",
    ]
  }

  statement {
    principals {
      type        = "AWS"
      identifiers = ["${aws_iam_role.admin_task.arn}"]
    }

    actions = [
      "ecs:RegisterTaskDefinition",
    ]

    resources = [
      # ECS doesn't provide more-specific permission for RegisterTaskDefinition
      "*",
    ]
  }

  statement {
    principals {
      type        = "AWS"
      identifiers = ["${aws_iam_role.admin_task.arn}"]
    }

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
    principals {
      type        = "AWS"
      identifiers = ["${aws_iam_role.admin_task.arn}"]
    }

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

  # For Fargate to start tasks
  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer"
    ]

    resources = [
      "*",
    ]
  }

  /* For ECS to fetch images */
  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]

    resources = [
      "${aws_ecr_repository.admin.arn}",
      "${aws_ecr_repository.jupyterlab_python.arn}",
      "${aws_ecr_repository.rstudio.arn}",
      "${aws_ecr_repository.rstudio_rv4.arn}",
      "${aws_ecr_repository.pgadmin.arn}",
      "${aws_ecr_repository.remotedesktop.arn}",
      "${aws_ecr_repository.theia.arn}",
      "${aws_ecr_repository.vscode.arn}",
      "${aws_ecr_repository.s3sync.arn}",
      "${aws_ecr_repository.metrics.arn}",
      "${aws_ecr_repository.sentryproxy.arn}",
      "${aws_ecr_repository.dns_rewrite_proxy.arn}",
      "${aws_ecr_repository.healthcheck.arn}",
      "${aws_ecr_repository.prometheus.arn}",
      "${aws_ecr_repository.gitlab.arn}",
      "${aws_ecr_repository.mirrors_sync.arn}",
      "${aws_ecr_repository.mirrors_sync_cran_binary.arn}",
      "${aws_ecr_repository.superset.arn}",
      "${aws_ecr_repository.airflow.arn}",
      "${aws_ecr_repository.flower.arn}",
      "${aws_ecr_repository.mlflow.arn}",
      "${aws_ecr_repository.datadog.arn}",
    ]
  }

  dynamic "statement" {
    for_each = var.matchbox_on ? [0] : []
    content {
      principals {
        type        = "AWS"
        identifiers = ["*"]
      }

      actions = [
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer",
      ]

      resources = [
        "${aws_ecr_repository.matchbox[0].arn}",
      ]
    }
  }

  # For GitLab runner to login and get base images
  dynamic "statement" {
    for_each = var.gitlab_on ? aws_iam_role.gitlab_runner[*].arn : []
    content {
      principals {
        type        = "AWS"
        identifiers = [statement.value]
      }
      actions = [
        "ecr:GetAuthorizationToken",
      ]

      resources = [
        "*",
      ]
    }
  }

  dynamic "statement" {
    for_each = var.gitlab_on ? aws_iam_role.gitlab_runner[*].arn : []
    content {
      principals {
        type        = "AWS"
        identifiers = [statement.value]
      }

      actions = [
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer",
      ]

      resources = [
        "${aws_ecr_repository.visualisation_base.arn}",
      ]
    }
  }

  # For GitLab runner to login and push user-provided images
  dynamic "statement" {
    for_each = var.gitlab_on ? aws_iam_role.gitlab_runner[*].arn : []
    content {
      principals {
        type        = "AWS"
        identifiers = [statement.value]
      }

      actions = [
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:GetRepositoryPolicy",
        "ecr:DescribeRepositories",
        "ecr:ListImages",
        "ecr:DescribeImages",
        "ecr:BatchGetImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:PutImage",
      ]
      resources = [
        "${aws_ecr_repository.user_provided.arn}",
      ]
    }
  }
}
