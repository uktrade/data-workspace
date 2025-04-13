resource "aws_db_parameter_group" "matchbox_postgres" {
  count       = var.matchbox_on ? 1 : 0
  name        = "${var.prefix}-matchbox-postgres"
  family      = "aurora-postgresql17"
  description = "Default parameters for Matchbox's PostgreSQL backend."

  dynamic "parameter" {
    for_each = var.matchbox_postgres_parameters
    content {
      name         = parameter.key
      value        = parameter.value
      apply_method = "immediate"
    }
  }
}

resource "aws_rds_cluster" "matchbox" {
  count                       = var.matchbox_on ? length(var.matchbox_instances) : 0
  cluster_identifier          = "${var.prefix}-matchbox-${var.matchbox_instances[count.index]}"
  engine                      = "aurora-postgresql"
  engine_version              = "17.4"
  allow_major_version_upgrade = true
  availability_zones          = var.aws_availability_zones
  database_name               = "${var.prefix_underscore}_matchbox_${var.matchbox_instances[count.index]}"
  master_username             = "${var.prefix_underscore}_matchbox_master_${var.matchbox_instances[count.index]}"
  master_password             = random_string.aws_db_instance_matchbox_password[count.index].result
  backup_retention_period     = 1
  preferred_backup_window     = "03:29-03:59"
  apply_immediately           = true

  vpc_security_group_ids = ["${aws_security_group.matchbox_db[count.index].id}"]
  db_subnet_group_name   = aws_db_subnet_group.matchbox[count.index].name

  final_snapshot_identifier = "${var.prefix}-matchbox-${var.matchbox_instances[count.index]}"
  copy_tags_to_snapshot     = true
}

resource "aws_rds_cluster_instance" "matchbox" {
  count                   = var.matchbox_on ? 1 : 0
  identifier              = "${var.prefix}-matchbox-${var.matchbox_instances[count.index]}"
  cluster_identifier      = aws_rds_cluster.matchbox[count.index].id
  engine                  = aws_rds_cluster.matchbox[count.index].engine
  engine_version          = aws_rds_cluster.matchbox[count.index].engine_version
  db_parameter_group_name = aws_db_parameter_group.matchbox_postgres[0].name
  instance_class          = var.matchbox_db_instance_class
  promotion_tier          = 1
}

resource "aws_db_subnet_group" "matchbox" {
  count      = var.matchbox_on ? 1 : 0
  name       = "${var.prefix}-matchbox"
  subnet_ids = aws_subnet.matchbox_private.*.id

  tags = {
    Name = "${var.prefix}-matchbox"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "random_string" "aws_db_instance_matchbox_password" {
  count   = var.matchbox_on ? length(var.matchbox_instances) : 0
  length  = 99
  special = false
}

resource "aws_rds_cluster_role_association" "matchbox_s3_import_role_association" {
  count                 = var.matchbox_on ? 1 : 0
  db_cluster_identifier = aws_rds_cluster.matchbox[count.index].id
  feature_name          = "s3Import"
  role_arn              = aws_iam_role.matchbox_s3_import[0].arn

  lifecycle {
    replace_triggered_by = [
      aws_rds_cluster.matchbox[count.index].id
    ]
  }
}

resource "aws_iam_role" "matchbox_s3_import" {
  count = var.matchbox_on ? 1 : 0
  name  = "${var.prefix}-matchbox-s3-import-association-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "rds.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "matchbox_s3_import" {
  count      = var.matchbox_on ? 1 : 0
  role       = aws_iam_role.matchbox_s3_import[0].name
  policy_arn = aws_iam_policy.matchbox_s3_import_policy[count.index].arn
}

resource "aws_iam_policy" "matchbox_s3_import_policy" {
  count  = var.matchbox_on ? 1 : 0
  name   = "${var.prefix}-rds-s3-access"
  path   = "/"
  policy = data.aws_iam_policy_document.matchbox_s3_import_policy_template[count.index].json
}

data "aws_iam_policy_document" "matchbox_s3_import_policy_template" {
  count = var.matchbox_on ? 1 : 0

  statement {
    actions = [
      "s3:GetObject",
    ]

    resources = ["arn:aws:s3:::${aws_s3_bucket.matchbox_s3_cache[count.index].id}/*"]
  }
}
