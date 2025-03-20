/*
resource "aws_rds_cluster" "sagemaker" {
  cluster_identifier      = "${var.prefix}-sagemaker"
  engine                  = "aurora-postgresql"
  database_name           = "sagemaker"
  master_username         = "sagemaker_master"
  master_password         = random_password.password.result
  backup_retention_period = 31
  preferred_backup_window = "03:29-03:59"
  apply_immediately       = true
  enable_http_endpoint    = true

  vpc_security_group_ids = [aws_security_group.sagemaker_db.id]
  db_subnet_group_name   = aws_db_subnet_group.sagemaker_db.name

  final_snapshot_identifier = "${var.prefix}-sagemaker-final-snapshot"

  copy_tags_to_snapshot          = true
  enable_global_write_forwarding = false

  serverlessv2_scaling_configuration {
    max_capacity = 1.0
    min_capacity = 0.0
  }
}

resource "aws_rds_cluster_instance" "sagemaker" {
  identifier         = "${var.prefix}-sagemaker"
  cluster_identifier = aws_rds_cluster.sagemaker.id
  engine             = aws_rds_cluster.sagemaker.engine
  engine_version     = aws_rds_cluster.sagemaker.engine_version
  instance_class     = "db.serverless"
}

// TODO: don't think I need both egress and ingress - which one is correct
resource "aws_security_group_rule" "notebooks_egress_postgres_to_sagemaker_db" {
  description = "egress-postgres-to-sagemaker-db"

  security_group_id        = var.notebooks_security_group_id
  source_security_group_id = aws_security_group.sagemaker_db.id

  type      = "egress"
  from_port = aws_rds_cluster.sagemaker.port
  to_port   = aws_rds_cluster.sagemaker.port
  protocol  = "tcp"
}

resource "aws_security_group_rule" "sagemaker_db_ingress_postgres_from_admin_service" {
  description = "ingress-postgres-from-sagemaker-db"

  security_group_id        = aws_security_group.sagemaker_db.id
  source_security_group_id = var.notebooks_security_group_id

  type      = "ingress"
  from_port = aws_rds_cluster.sagemaker.port
  to_port   = aws_rds_cluster.sagemaker.port
  protocol  = "tcp"
}

resource "aws_db_subnet_group" "sagemaker_db" {
  name       = "${var.prefix}-sagemaker-db"
  subnet_ids = var.aws_subnet_main

  tags = {
    Name = "${var.prefix}-sagemaker-db"
  }
}

resource "aws_security_group" "sagemaker_db" {
  name        = "${var.prefix}-sagemaker-db"
  description = "${var.prefix}-sagemaker-db"
  vpc_id      = var.vpc_id_main

  tags = {
    Name = "${var.prefix}-sagemaker-db"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_secretsmanager_secret" "sagemaker_db" {
  name        = "sagemaker_master"
  description = "Password for user sagemaker_master"

  tags = {
    Name = "${var.prefix}-sagemaker-db"
  }
}

resource "aws_secretsmanager_secret_version" "secret" {
  secret_id     = aws_secretsmanager_secret.sagemaker_db.id
  secret_string = random_password.password.result
}

resource "random_password" "password" {
  length  = 16
  special = true
}
*/
