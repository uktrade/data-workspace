resource "aws_ebs_volume" "arango" {
  count             = var.arango_on ? 1 : 0
  availability_zone = var.aws_availability_zones[0]
  size              = var.arango_ebs_volume_size
  type              = var.arango_ebs_volume_type
  encrypted         = true

  lifecycle {
    prevent_destroy = false
  }

  tags = {
    Name = "${var.prefix}-arango"
  }
}


resource "aws_backup_vault" "arango_backup_vault" {
  count = var.arango_on ? 1 : 0
  name  = "${var.prefix}-arangodb-backup-vault"
}

resource "aws_backup_plan" "arango_backup_plan" {
  count = var.arango_on ? 1 : 0
  name  = "${var.prefix}-arangodb-backup-plan"
  rule {
    rule_name         = "arangodb-backup-rule"
    target_vault_name = "${var.prefix}-arangodb-backup-vault"
    schedule          = "cron(0 0 * * ? *)"

    start_window      = 60
    completion_window = 360
    lifecycle {
      delete_after = 8
    }
  }

  depends_on = [aws_backup_vault.arango_backup_vault]
}

resource "aws_backup_selection" "arango_backup_resource" {
  count        = var.arango_on ? 1 : 0
  iam_role_arn = aws_iam_role.arango_ebs_backup[0].arn
  name         = "arangodb-backup-resources"
  plan_id      = aws_backup_plan.arango_backup_plan[0].id

  resources = [
    aws_ebs_volume.arango[0].arn
  ]
}

resource "aws_iam_role_policy_attachment" "arango_ec2_ebs_backup" {
  count      = var.arango_on ? 1 : 0
  role       = aws_iam_role.arango_ebs_backup[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}


resource "aws_iam_role" "arango_ebs_backup" {
  count              = var.arango_on ? 1 : 0
  name               = "${var.prefix}-arango-ebs-backup"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.arango_ebs_backup_assume_role[0].json
}

data "aws_iam_policy_document" "arango_ebs_backup_assume_role" {
  count = var.arango_on ? 1 : 0
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
  }
}
