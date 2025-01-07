// We only ever deploy tagged images, so all ECR repos have a lifecycle policy to delete untagged
// images.
//
// The current exceptions are the visualisation_base repos, where historically images were used
// using the sha256 hash, although at the time of writing we're moving away from this.

resource "aws_ecr_repository" "user_provided" {
  name         = "${var.prefix}-user-provided"
  force_delete = false
}

resource "aws_ecr_lifecycle_policy" "user_provided_expire_untagged_after_one_day" {
  repository = aws_ecr_repository.user_provided.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_untagged_after_one_day.json
}

resource "aws_ecr_repository" "admin" {
  name         = "${var.prefix}-admin"
  force_delete = false
}

resource "aws_ecr_lifecycle_policy" "admin_expire_untagged_after_one_day" {
  repository = aws_ecr_repository.admin.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_untagged_after_one_day.json
}

resource "aws_ecr_repository" "jupyterlab_python" {
  name         = "${var.prefix}-jupyterlab-python"
  force_delete = false
}

resource "aws_ecr_lifecycle_policy" "jupyterlab_python_expire_untagged_after_one_day" {
  repository = aws_ecr_repository.jupyterlab_python.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_untagged_after_one_day.json
}

resource "aws_ecr_repository" "rstudio" {
  name         = "${var.prefix}-rstudio"
  force_delete = false
}

resource "aws_ecr_lifecycle_policy" "rstudio_expire_untagged_after_one_day" {
  repository = aws_ecr_repository.rstudio.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_untagged_after_one_day.json
}

resource "aws_ecr_repository" "rstudio_rv4" {
  name         = "${var.prefix}-rstudio-rv4"
  force_delete = false
}

resource "aws_ecr_lifecycle_policy" "rstudio_rv4_expire_untagged_after_one_day" {
  repository = aws_ecr_repository.rstudio_rv4.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_untagged_after_one_day.json
}

resource "aws_ecr_repository" "pgadmin" {
  name         = "${var.prefix}-pgadmin"
  force_delete = false
}

resource "aws_ecr_lifecycle_policy" "pgadmin_expire_untagged_after_one_day" {
  repository = aws_ecr_repository.pgadmin.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_untagged_after_one_day.json
}

resource "aws_ecr_repository" "remotedesktop" {
  name         = "${var.prefix}-remotedesktop"
  force_delete = false
}

resource "aws_ecr_lifecycle_policy" "remotedesktop_rv4_expire_untagged_after_one_day" {
  repository = aws_ecr_repository.remotedesktop.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_untagged_after_one_day.json
}

resource "aws_ecr_repository" "theia" {
  name         = "${var.prefix}-theia"
  force_delete = false
}

resource "aws_ecr_lifecycle_policy" "theia_expire_untagged_after_one_day" {
  repository = aws_ecr_repository.theia.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_untagged_after_one_day.json
}

resource "aws_ecr_repository" "vscode" {
  name         = "${var.prefix}-vscode"
  force_delete = false
}

resource "aws_ecr_lifecycle_policy" "vscode_expire_untagged_after_one_day" {
  repository = aws_ecr_repository.vscode.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_untagged_after_one_day.json
}

resource "aws_ecr_repository" "s3sync" {
  name         = "${var.prefix}-s3sync"
  force_delete = false
}

resource "aws_ecr_lifecycle_policy" "s3sync_expire_untagged_after_one_day" {
  repository = aws_ecr_repository.s3sync.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_untagged_after_one_day.json
}

resource "aws_ecr_repository" "metrics" {
  name         = "${var.prefix}-metrics"
  force_delete = false
}

resource "aws_ecr_lifecycle_policy" "metrics_expire_untagged_after_one_day" {
  repository = aws_ecr_repository.metrics.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_untagged_after_one_day.json
}

resource "aws_ecr_repository" "sentryproxy" {
  name         = "${var.prefix}-sentryproxy"
  force_delete = false
}


resource "aws_ecr_lifecycle_policy" "sentryproxy_expire_untagged_after_one_day" {
  repository = aws_ecr_repository.sentryproxy.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_untagged_after_one_day.json
}

resource "aws_ecr_repository" "dns_rewrite_proxy" {
  name         = "${var.prefix}-dns-rewrite-proxy"
  force_delete = false
}

resource "aws_ecr_lifecycle_policy" "dns_rewrite_proxy_expire_untagged_after_one_day" {
  repository = aws_ecr_repository.dns_rewrite_proxy.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_untagged_after_one_day.json
}

resource "aws_ecr_repository" "healthcheck" {
  name         = "${var.prefix}-healthcheck"
  force_delete = false
}

resource "aws_ecr_lifecycle_policy" "healthcheck_expire_untagged_after_one_day" {
  repository = aws_ecr_repository.healthcheck.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_untagged_after_one_day.json
}

resource "aws_ecr_repository" "prometheus" {
  name         = "${var.prefix}-prometheus"
  force_delete = false
}

resource "aws_ecr_lifecycle_policy" "prometheus_expire_untagged_after_one_day" {
  repository = aws_ecr_repository.prometheus.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_untagged_after_one_day.json
}

resource "aws_ecr_repository" "gitlab" {
  name         = "${var.prefix}-gitlab"
  force_delete = false
}

resource "aws_ecr_lifecycle_policy" "gitlab_expire_untagged_after_one_day" {
  repository = aws_ecr_repository.gitlab.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_untagged_after_one_day.json
}

resource "aws_ecr_repository" "visualisation_base" {
  name         = "${var.prefix}-visualisation-base"
  force_delete = false
}

resource "aws_ecr_repository" "visualisation_base_r" {
  name         = "${var.prefix}-visualisation-base-r"
  force_delete = false
}

resource "aws_ecr_repository" "visualisation_base_rv4" {
  name         = "${var.prefix}-visualisation-base-rv4"
  force_delete = false
}

resource "aws_ecr_repository" "mirrors_sync" {
  name         = "${var.prefix}-mirrors-sync"
  force_delete = false
}

resource "aws_ecr_lifecycle_policy" "mirrors_sync_expire_untagged_after_one_day" {
  repository = aws_ecr_repository.mirrors_sync.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_untagged_after_one_day.json
}

resource "aws_ecr_repository" "mirrors_sync_cran_binary" {
  name         = "${var.prefix}-mirrors-sync-cran-binary"
  force_delete = false
}

resource "aws_ecr_lifecycle_policy" "mirrors_sync_cran_binary_expire_untagged_after_one_day" {
  repository = aws_ecr_repository.mirrors_sync_cran_binary.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_untagged_after_one_day.json
}

resource "aws_ecr_repository" "mirrors_sync_cran_binary_rv4" {
  name         = "${var.prefix}-mirrors-sync-cran-binary-rv4"
  force_delete = false
}

resource "aws_ecr_lifecycle_policy" "mirrors_sync_cran_binary_rv4_expire_untagged_after_one_day" {
  repository = aws_ecr_repository.mirrors_sync_cran_binary_rv4.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_untagged_after_one_day.json
}

resource "aws_ecr_repository" "superset" {
  name         = "${var.prefix}-superset"
  force_delete = false
}

resource "aws_ecr_lifecycle_policy" "superset_expire_untagged_after_one_day" {
  repository = aws_ecr_repository.superset.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_untagged_after_one_day.json
}

resource "aws_ecr_repository" "airflow" {
  name         = "${var.prefix}-airflow"
  force_delete = false
}

resource "aws_ecr_lifecycle_policy" "airflow_expire_untagged_after_one_day" {
  repository = aws_ecr_repository.airflow.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_untagged_after_one_day.json
}

resource "aws_ecr_repository" "flower" {
  name         = "${var.prefix}-flower"
  force_delete = false
}

resource "aws_ecr_lifecycle_policy" "flower_expire_untagged_after_one_day" {
  repository = aws_ecr_repository.flower.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_untagged_after_one_day.json
}

resource "aws_ecr_repository" "mlflow" {
  name         = "${var.prefix}-mlflow"
  force_delete = false
}

resource "aws_ecr_lifecycle_policy" "mlflow_expire_untagged_after_one_day" {
  repository = aws_ecr_repository.mlflow.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_untagged_after_one_day.json
}

resource "aws_ecr_repository" "arango" {
  count        = var.arango_on ? 1 : 0
  name         = "${var.prefix}-arango"
  force_delete = false
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

resource "aws_ecr_repository" "sagemaker" {
  name         = "${var.prefix}-sagemaker"
  force_delete = false
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
    ]
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
        "${aws_ecr_repository.visualisation_base_r.arn}",
        "${aws_ecr_repository.visualisation_base_rv4.arn}",
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
