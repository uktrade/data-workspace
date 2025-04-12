data "external" "dns_rewrite_proxy_current_tag" {
  program = ["${path.module}/container-tag.sh"]

  query = {
    cluster_name   = "${aws_ecs_cluster.main_cluster.name}"
    service_name   = "${var.prefix}-dns-rewrite-proxy" # Manually specified to avoid a cycle
    container_name = "${local.dns_rewrite_proxy_container_name}"
  }
}

resource "aws_cloudwatch_log_group" "dns_rewrite_proxy" {
  name              = "${var.prefix}-dns-rewrite-proxy"
  retention_in_days = "3653"
}

resource "aws_cloudwatch_log_subscription_filter" "dns_rewrite_proxy" {
  count           = var.cloudwatch_subscription_filter ? 1 : 0
  name            = "${var.prefix}-dns-rewrite-proxy"
  log_group_name  = aws_cloudwatch_log_group.dns_rewrite_proxy.name
  filter_pattern  = ""
  destination_arn = var.cloudwatch_destination_arn
}

resource "aws_iam_role" "dns_rewrite_proxy_task_execution" {
  name               = "${var.prefix}-dns-rewrite-proxy-task-execution"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.dns_rewrite_proxy_task_execution_ecs_tasks_assume_role.json
}

data "aws_iam_policy_document" "dns_rewrite_proxy_task_execution_ecs_tasks_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "dns_rewrite_proxy_task_execution" {
  role       = aws_iam_role.dns_rewrite_proxy_task_execution.name
  policy_arn = aws_iam_policy.dns_rewrite_proxy_task_execution.arn
}

resource "aws_iam_policy" "dns_rewrite_proxy_task_execution" {
  name   = "${var.prefix}-dns-rewrite-proxy-task-execution"
  path   = "/"
  policy = data.aws_iam_policy_document.dns_rewrite_proxy_task_execution.json
}

data "aws_iam_policy_document" "dns_rewrite_proxy_task_execution" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "${aws_cloudwatch_log_group.dns_rewrite_proxy.arn}:*",
    ]
  }

  statement {
    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]

    resources = [
      "${aws_ecr_repository.dns_rewrite_proxy.arn}",
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

resource "aws_iam_role" "dns_rewrite_proxy_task" {
  name               = "${var.prefix}-dns-rewrite-proxy-task"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.dns_rewrite_proxy_task_ecs_tasks_assume_role.json
}

resource "aws_iam_role_policy_attachment" "dns_rewrite_proxy" {
  role       = aws_iam_role.dns_rewrite_proxy_task.name
  policy_arn = aws_iam_policy.dns_rewrite_proxy_task.arn
}

resource "aws_iam_policy" "dns_rewrite_proxy_task" {
  name   = "${var.prefix}-dns-rewrite-proxy-task"
  path   = "/"
  policy = data.aws_iam_policy_document.dns_rewrite_proxy_task.json
}

data "aws_iam_policy_document" "dns_rewrite_proxy_task" {
  statement {
    actions = [
      "ec2:AssociateDhcpOptions",
      "ec2:CreateDhcpOptions",
      "ec2:CreateTags",
      "ec2:DeleteDhcpOptions",
      "ec2:DescribeVpcs",
    ]

    resources = [
      "*",
    ]
  }
}

data "aws_iam_policy_document" "dns_rewrite_proxy_task_ecs_tasks_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}
