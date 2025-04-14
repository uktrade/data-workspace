
resource "aws_ebs_volume" "gitlab" {
  count             = var.gitlab_on ? 1 : 0
  availability_zone = var.aws_availability_zones[0]
  size              = var.gitlab_ebs_volume_size
  encrypted         = true

  lifecycle {
    prevent_destroy = false
  }

  tags = {
    Name = "${var.prefix}-gitlab"
  }
}

resource "aws_backup_vault" "gitlab" {
  count = var.gitlab_on ? 1 : 0
  name  = "${var.prefix}-gitlab"
}

resource "aws_backup_plan" "gitlab" {
  count = var.gitlab_on ? 1 : 0
  name  = "${var.prefix}-gitlab"
  rule {
    rule_name         = "gitlab"
    target_vault_name = aws_backup_vault.gitlab[0].name
    schedule          = "cron(0 0 * * ? *)"

    start_window      = 60
    completion_window = 360
    lifecycle {
      delete_after = 365
    }
  }
}

resource "aws_backup_selection" "gitlab" {
  count        = var.gitlab_on ? 1 : 0
  iam_role_arn = aws_iam_role.gitlab_backup[0].arn
  name         = "gitlab"
  plan_id      = aws_backup_plan.gitlab[0].id

  resources = [
    aws_ebs_volume.gitlab[0].arn
  ]
}

resource "aws_iam_role" "gitlab_backup" {
  count              = var.gitlab_on ? 1 : 0
  name               = "${var.prefix}-gitlab-backup"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.gitlab_backup_assume_role[0].json
}

data "aws_iam_policy_document" "gitlab_backup_assume_role" {
  count = var.gitlab_on ? 1 : 0
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "gitlab_backup" {
  count      = var.gitlab_on ? 1 : 0
  role       = aws_iam_role.gitlab_backup[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}