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
  count = var.matchbox_on ? 1 : 0

  cluster_identifier           = "${var.prefix}-matchbox-${var.matchbox_environment}"
  engine                       = "aurora-postgresql"
  engine_version               = "17.4"
  engine_mode                  = "provisioned" # NOTE: "provisioned" for Aurora Serverless v2 ("serverless" is for v1)
  allow_major_version_upgrade  = true
  availability_zones           = var.aws_availability_zones
  database_name                = "${var.prefix_underscore}_matchbox_${var.matchbox_environment}"
  master_username              = "${var.prefix_underscore}_matchbox_master_${var.matchbox_environment}"
  master_password              = random_password.db_password[0].result
  backup_retention_period      = 1
  preferred_backup_window      = "03:29-03:59"
  apply_immediately            = true
  performance_insights_enabled = var.matchbox_db_performance_insights
  enable_http_endpoint         = var.matchbox_db_http_endpoint
  storage_encrypted            = true

  serverlessv2_scaling_configuration {
    min_capacity             = var.matchbox_db_scaling.min_capacity
    max_capacity             = var.matchbox_db_scaling.max_capacity
    seconds_until_auto_pause = var.matchbox_db_scaling.scaledown_seconds
  }

  vpc_security_group_ids = ["${aws_security_group.matchbox_db[0].id}"]
  db_subnet_group_name   = aws_db_subnet_group.matchbox[0].name

  final_snapshot_identifier = "${var.prefix}-matchbox-${var.matchbox_environment}"
  copy_tags_to_snapshot     = true
}

resource "aws_rds_cluster_instance" "matchbox" {
  count = var.matchbox_on ? length(var.matchbox_db_instances) : 0

  identifier                 = "${var.prefix}-matchbox-${var.matchbox_environment}-${var.matchbox_db_instances[count.index]}"
  cluster_identifier         = aws_rds_cluster.matchbox[0].id
  engine                     = aws_rds_cluster.matchbox[0].engine
  engine_version             = aws_rds_cluster.matchbox[0].engine_version
  db_parameter_group_name    = aws_db_parameter_group.matchbox_postgres[0].name
  instance_class             = "db.serverless"
  promotion_tier             = count.index
  monitoring_interval        = 0
  auto_minor_version_upgrade = true
  copy_tags_to_snapshot      = false
  force_destroy              = false
  apply_immediately          = true
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

resource "aws_secretsmanager_secret" "db_password" {
  count = var.matchbox_on ? 1 : 0

  name = "matchbox_db_password"
}

resource "aws_secretsmanager_secret_version" "db_password" {
  count = var.matchbox_on ? 1 : 0

  secret_id     = aws_secretsmanager_secret.db_password[count.index].id
  secret_string = random_password.db_password[count.index].result
}

resource "random_password" "db_password" {
  count = var.matchbox_on ? 1 : 0

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

resource "aws_security_group" "matchbox_db" {
  count = var.matchbox_on ? 1 : 0

  name        = "${var.prefix}-matchbox-${var.matchbox_environment}-db"
  description = "${var.prefix}-matchbox-${var.matchbox_environment}-db"
  vpc_id      = aws_vpc.matchbox[0].id

  tags = {
    Name = "${var.prefix}-matchbox-${var.matchbox_environment}-db"
  }
  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_security_group_rule" "matchbox_db_egress_https_to_matchbox_s3_endpoint" {
  count = var.matchbox_on ? 1 : 0

  description       = "egress-https-to-s3"
  security_group_id = aws_security_group.matchbox_db[count.index].id
  prefix_list_ids   = [aws_vpc_endpoint.matchbox_endpoint_s3[0].prefix_list_id]

  type      = "egress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}
