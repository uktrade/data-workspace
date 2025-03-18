resource "aws_db_instance" "sagemaker" {
  identifier = "${var.prefix}-sagemaker"

  allocated_storage     = var.sagemaker_db_instance_allocated_storage
  max_allocated_storage = var.sagemaker_db_instance_max_allocated_storage
  storage_type          = "gp2"
  engine                = "postgres"
  engine_version        = var.sagemaker_db_instance_version
  instance_class        = var.sagemaker_db_instance_class

  apply_immediately     = true

  backup_retention_period = 31
  backup_window           = "03:29-03:59"

  db_name  = "sagemaker"
  username = "sagemaker_master"
  password = random_string.aws_db_instance_sagemaker_password.result

  final_snapshot_identifier     = "${var.prefix}-sagemaker-final-snapshot"
  copy_tags_to_snapshot         = true

  vpc_security_group_ids        = [aws_security_group.sagemaker_db.id]
  db_subnet_group_name          = aws_db_subnet_group.sagemaker.name

  performance_insights_enabled  = true
  storage_encrypted             = true

  lifecycle {
    ignore_changes = [
      snapshot_identifier,
      final_snapshot_identifier,
      engine_version,
    ]
  }
}

resource "aws_security_group" "sagemaker_db" {
  name        = "${var.prefix}-sagemaker-db"
  description = "${var.prefix}-sagemaker-db"
  vpc_id      = var.vpc_id_sagemaker

  tags = {
    Name = "${var.prefix}-sagemaker-db"
  }

  lifecycle {
    create_before_destroy = true
  }
}

// TODO: don't think I need both egress and ingress - which one is correct
resource "aws_security_group_rule" "notebooks_egress_postgres_to_sagemaker_db" {
  description = "egress-postgres-to-sagemaker-db"

  security_group_id        = var.notebooks_security_group_id
  source_security_group_id = aws_security_group.sagemaker_db.id

  type      = "egress"
  from_port = aws_db_instance.sagemaker.port
  to_port   = aws_db_instance.sagemaker.port
  protocol  = "tcp"
}

resource "aws_security_group_rule" "sagemaker_db_ingress_postgres_from_admin_service" {
  description = "ingress-postgres-from-admin-service"

  security_group_id        = aws_security_group.sagemaker_db.id
  source_security_group_id = var.notebooks_security_group_id

  type      = "ingress"
  from_port = aws_db_instance.sagemaker.port
  to_port   = aws_db_instance.sagemaker.port
  protocol  = "tcp"
}

resource "aws_db_subnet_group" "sagemaker" {
  name       = "${var.prefix}-sagemaker"
  subnet_ids = var.aws_subnet_sagemaker

  tags = {
    Name = "${var.prefix}-sagemaker"
  }
}

resource "random_string" "aws_db_instance_sagemaker_password" {
  length  = 128
  special = false
}
