# Typically we don't have a separate file for IAM-related infrastructure in Data Workspace.
# However, Airflow is an exception for 2 reasons:
#
# 1. The IAM policy for an Airflow team role is shared between the DAG processor and team tasks. In
#    most other cases in the Terraform a policy is _not_ shared between different resources, and so#
#    makes sense to be in the same file as the resource controlled by the policy
# 2. The permissions associate with Airflow team roles comes up a lot in conversations, and so it
#    makes sense to be able to point to a specific file. This is not the case for most other IAM
#    policies

resource "aws_iam_role" "airflow_team" {
  count              = var.airflow_on ? length(var.airflow_dag_processors) : 0
  name               = "${local.airflow_team_role_prefix}${var.airflow_dag_processors[count.index].name}"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.airflow_dag_processor_task_ecs_tasks_assume_role[count.index].json
}

resource "aws_iam_policy" "airflow_team" {
  count  = var.airflow_on ? length(var.airflow_dag_processors) : 0
  name   = "${local.airflow_team_role_prefix}${var.airflow_dag_processors[count.index].name}"
  path   = "/"
  policy = data.aws_iam_policy_document.airflow_team[count.index].json
}

resource "aws_iam_role_policy_attachment" "airflow_team" {
  count      = var.airflow_on ? length(var.airflow_dag_processors) : 0
  role       = aws_iam_role.airflow_team[count.index].name
  policy_arn = aws_iam_policy.airflow_team[count.index].arn
}

data "aws_iam_policy_document" "airflow_team" {
  count = var.airflow_on ? length(var.airflow_dag_processors) : 0

  dynamic "statement" {
    for_each = length(var.airflow_dag_processors[count.index].assume_roles) > 0 ? [1] : []
    content {
      actions = [
        "sts:AssumeRole",
      ]
      resources = var.airflow_dag_processors[count.index].assume_roles
    }
  }

  dynamic "statement" {
    for_each = length(var.airflow_dag_processors[count.index].buckets) > 0 ? [1] : []
    content {
      actions = [
        "s3:ListBucket",
      ]
      resources = var.airflow_dag_processors[count.index].buckets
    }
  }

  dynamic "statement" {
    for_each = length(var.airflow_dag_processors[count.index].buckets) > 0 ? [1] : []
    content {
      actions = [
        "s3:GetObject",
      ]
      resources = [for s in var.airflow_dag_processors[count.index].buckets : "${s}/*"]
    }
  }

  dynamic "statement" {
    for_each = length(var.airflow_dag_processors[count.index].keys) > 0 ? [1] : []
    content {
      actions = [
        "kms:Decrypt",
      ]
      resources = var.airflow_dag_processors[count.index].keys
    }
  }

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

    # Should be tighter
    resources = [
      "*"
    ]
  }

  statement {
    actions = [
      "secretsmanager:GetSecretValue"
    ]

    resources = [
      "arn:aws:secretsmanager:${data.aws_region.aws_region.name}:${data.aws_caller_identity.aws_caller_identity.account_id}:secret:${var.prefix}/airflow/${var.airflow_dag_processors[count.index].name}-*",
      "arn:aws:secretsmanager:${data.aws_region.aws_region.name}:${data.aws_caller_identity.aws_caller_identity.account_id}:secret:${var.prefix}/airflow/${var.airflow_dag_processors[count.index].name}_2-*"
    ]
  }

  # This just gives a permission to call BatchGetSecretValue, but doesn't actually give permission
  # to look at any secret values themselves - secretsmanager:GetSecretValue does that
  statement {
    actions = [
      "secretsmanager:BatchGetSecretValue"
    ]

    resources = [
      "*"
    ]
  }

  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject"
    ]

    resources = [
      "${aws_s3_bucket.airflow[count.index].arn}/*",
    ]
  }

  statement {
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
    ]

    resources = [
      "${aws_s3_bucket.airflow[count.index].arn}",
    ]
  }
}
