# Usually IAM-related role definition are in the same files as the resoures that assume those
# roles. However, both the frontend webserver and celery assume the same roles, so we separate
# out those resources

resource "aws_iam_role" "admin_task_execution" {
  name               = "${var.prefix}-admin-task-execution"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.admin_task_execution_ecs_tasks_assume_role.json
}

data "aws_iam_policy_document" "admin_task_execution_ecs_tasks_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "admin_task_execution" {
  role       = aws_iam_role.admin_task_execution.name
  policy_arn = aws_iam_policy.admin_task_execution.arn
}

resource "aws_iam_policy" "admin_task_execution" {
  name   = "${var.prefix}-admin-task-execution"
  path   = "/"
  policy = data.aws_iam_policy_document.admin_task_execution.json
}

data "aws_iam_policy_document" "admin_task_execution" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "${aws_cloudwatch_log_group.admin.arn}:*",
    ]
  }

  statement {
    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]

    resources = [
      "${aws_ecr_repository.admin.arn}",
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

resource "aws_iam_role" "admin_dashboard_embedding" {
  name               = "${var.prefix}-quicksight-embedding"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.admin_dashboard_embedding_assume_role.json
}

resource "aws_iam_policy" "admin_dashboard_embedding" {
  name   = "${var.prefix}-quicksight-dashboard-embedding"
  path   = "/"
  policy = data.aws_iam_policy_document.admin_dashboard_embedding.json
}

data "aws_iam_policy_document" "admin_dashboard_embedding" {
  statement {
    actions   = ["quicksight:RegisterUser"]
    resources = ["*"]
  }
  statement {
    actions   = ["quicksight:CreateGroupMembership"]
    resources = ["*"]
  }
  statement {
    actions   = ["quicksight:DescribeDashboard"]
    resources = ["*"]
  }
  statement {
    actions   = ["quicksight:GetDashboardEmbedUrl"]
    resources = ["arn:aws:quicksight:*:${data.aws_caller_identity.aws_caller_identity.account_id}:dashboard/*"]
  }
  statement {
    actions   = ["quicksight:GetAuthCode"]
    resources = ["arn:aws:quicksight:*:${data.aws_caller_identity.aws_caller_identity.account_id}:user/${var.quicksight_namespace}/${var.prefix}-quicksight-embedding/*"]
  }
}

data "aws_iam_policy_document" "admin_dashboard_embedding_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["${aws_iam_role.admin_task.arn}"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "admin_dashboard_embedding" {
  role       = aws_iam_role.admin_dashboard_embedding.name
  policy_arn = aws_iam_policy.admin_dashboard_embedding.arn
}

resource "aws_iam_role" "admin_task" {
  name               = "${var.prefix}-admin-task"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.admin_task_ecs_tasks_assume_role.json
}

resource "aws_iam_role_policy_attachment" "admin_access_uploads_bucket" {
  role       = aws_iam_role.admin_task.name
  policy_arn = aws_iam_policy.admin_access_uploads_bucket.arn
}

resource "aws_iam_policy" "admin_access_uploads_bucket" {
  name   = "${var.prefix}-admin-access-uploads-bucket"
  path   = "/"
  policy = data.aws_iam_policy_document.admin_access_uploads_bucket.json
}

data "aws_iam_policy_document" "admin_access_uploads_bucket" {
  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject"
    ]

    resources = [
      "${aws_s3_bucket.uploads.arn}/*",
    ]
  }

  statement {
    actions = [
      "s3:GetBucketLocation",
    ]

    resources = [
      "${aws_s3_bucket.uploads.arn}",
    ]
  }
}

resource "aws_iam_role_policy_attachment" "admin_run_tasks" {
  role       = aws_iam_role.admin_task.name
  policy_arn = aws_iam_policy.admin_run_tasks.arn
}

resource "aws_iam_policy" "admin_run_tasks" {
  name   = "${var.prefix}-admin-run-tasks"
  path   = "/"
  policy = data.aws_iam_policy_document.admin_run_tasks.json
}

data "aws_iam_policy_document" "admin_run_tasks" {
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

    resources = concat([
      "arn:aws:ecs:${data.aws_region.aws_region.name}:${data.aws_caller_identity.aws_caller_identity.account_id}:task-definition/${aws_ecs_task_definition.user_provided.family}-*",
      ],
      [for i, v in var.tools : "arn:aws:ecs:${data.aws_region.aws_region.name}:${data.aws_caller_identity.aws_caller_identity.account_id}:task-definition/${aws_ecs_task_definition.tools[i].family}"],
      [for i, v in var.tools : "arn:aws:ecs:${data.aws_region.aws_region.name}:${data.aws_caller_identity.aws_caller_identity.account_id}:task-definition/${aws_ecs_task_definition.tools[i].family}-*"],
    )
  }

  statement {
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
    actions = [
      "ecs:DescribeTaskDefinition",
    ]

    resources = [
      # ECS doesn't provide more-specific permission for DescribeTaskDefinition
      "*",
    ]
  }

  statement {
    actions = [
      "ecs:RegisterTaskDefinition",
    ]

    resources = [
      # ECS doesn't provide more-specific permission for RegisterTaskDefinition
      "*",
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
      "iam:PassRole"
    ]
    resources = [
      "${aws_iam_role.notebook_task_execution.arn}",
    ]
  }

  statement {
    actions = [
      "iam:GetRole",
      "iam:PassRole",
      "iam:UpdateAssumeRolePolicy",

      # The admin application creates temporary credentials, via AssumeRole, for a
      # user to manage their files in S3. The role, and therfore permissions are
      # exactly the ones that a user's containers can assume
      "sts:AssumeRole",
    ]

    resources = [
      "arn:aws:iam::${data.aws_caller_identity.aws_caller_identity.account_id}:role/${var.notebook_task_role_prefix}*"
    ]
  }

  statement {
    actions = [
      "iam:CreateRole",
      "iam:PutRolePolicy",
    ]

    resources = [
      "arn:aws:iam::${data.aws_caller_identity.aws_caller_identity.account_id}:role/${var.notebook_task_role_prefix}*"
    ]

    # The boundary means that JupyterHub can't create abitrary roles:
    # they must have this boundary attached. At most, they will
    # be able to have access to the entire bucket, and only
    # from inside the VPC
    condition {
      test     = "StringEquals"
      variable = "iam:PermissionsBoundary"
      values = [
        "${aws_iam_policy.notebook_task_boundary.arn}",
      ]
    }
  }

  statement {
    actions = [
      "quicksight:*",
    ]

    resources = [
      # ECS doesn't provide more-specific permission for RegisterTaskDefinition
      "*",
    ]
  }

  statement {
    actions = [
      "sts:AssumeRole",
    ]

    resources = [
      "${aws_iam_role.admin_dashboard_embedding.arn}"
    ]
  }
}

resource "aws_iam_role_policy_attachment" "admin_admin_store_db_creds_in_s3_task" {
  role       = aws_iam_role.admin_task.name
  policy_arn = aws_iam_policy.admin_store_db_creds_in_s3_task.arn
}

resource "aws_iam_role" "admin_store_db_creds_in_s3_task" {
  name               = "${var.prefix}-admin-store-db-creds-in-s3-task"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.admin_task_ecs_tasks_assume_role.json
}

resource "aws_iam_role_policy_attachment" "admin_store_db_creds_in_s3_task" {
  role       = aws_iam_role.admin_store_db_creds_in_s3_task.name
  policy_arn = aws_iam_policy.admin_store_db_creds_in_s3_task.arn
}

resource "aws_iam_policy" "admin_store_db_creds_in_s3_task" {
  name   = "${var.prefix}-admin-store-db-creds-in-s3-task"
  path   = "/"
  policy = data.aws_iam_policy_document.admin_store_db_creds_in_s3_task.json
}

data "aws_iam_policy_document" "admin_store_db_creds_in_s3_task" {
  statement {
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl",
    ]

    resources = [
      "${aws_s3_bucket.notebooks.arn}/*",
      "arn:aws:s3:::appstream2-36fb080bb8-eu-west-1-664841488776/*",
    ]
  }
}

data "aws_iam_policy_document" "admin_task_ecs_tasks_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "admin_cloudwatch_logs" {
  role       = aws_iam_role.admin_task.name
  policy_arn = aws_iam_policy.admin_cloudwatch_logs.arn
}

resource "aws_iam_policy" "admin_cloudwatch_logs" {
  name   = "${var.prefix}-admin-cloudwatch-logs"
  path   = "/"
  policy = data.aws_iam_policy_document.admin_cloudwatch_logs.json
}

data "aws_iam_policy_document" "admin_cloudwatch_logs" {
  statement {
    actions   = ["logs:GetLogEvents"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy_attachment" "admin_datasets_database_rds_logs" {
  role       = aws_iam_role.admin_task.name
  policy_arn = aws_iam_policy.admin_datasets_database_rds_logs.arn
}

resource "aws_iam_policy" "admin_datasets_database_rds_logs" {
  name   = "${var.prefix}-admin-datasets-database-rds-logs"
  path   = "/"
  policy = data.aws_iam_policy_document.admin_datasets_database_rds_logs.json
}

data "aws_iam_policy_document" "admin_datasets_database_rds_logs" {
  statement {
    actions = [
      "rds:DownloadDBLogFilePortion",
      "rds:DescribeDBLogFiles"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy_attachment" "admin_list_ecs_tasks" {
  role       = aws_iam_role.admin_task.name
  policy_arn = aws_iam_policy.admin_list_ecs_tasks.arn
}

resource "aws_iam_policy" "admin_list_ecs_tasks" {
  name   = "${var.prefix}-admin-list-ecs-tasks"
  path   = "/"
  policy = data.aws_iam_policy_document.admin_list_ecs_tasks.json
}

data "aws_iam_policy_document" "admin_list_ecs_tasks" {
  statement {
    actions = [
      "ecs:ListTasks",
      "ecs:DescribeTasks"
    ]
    resources = ["*"]

    condition {
      test     = "ArnEquals"
      variable = "ecs:cluster"
      values = [
        "arn:aws:ecs:${data.aws_region.aws_region.name}:${data.aws_caller_identity.aws_caller_identity.account_id}:cluster/${aws_ecs_cluster.notebooks.name}",
      ]
    }
  }
}