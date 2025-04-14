resource "aws_rds_cluster" "airflow" {
  count                   = var.airflow_on ? 1 : 0
  cluster_identifier      = "${var.prefix}-airflow"
  engine                  = "aurora-postgresql"
  availability_zones      = var.aws_availability_zones
  database_name           = "${var.prefix_underscore}_airflow"
  master_username         = "${var.prefix_underscore}_airflow_master"
  master_password         = random_string.aws_db_instance_airflow_password.result
  backup_retention_period = 31
  preferred_backup_window = "03:29-03:59"
  apply_immediately       = true

  vpc_security_group_ids = ["${aws_security_group.airflow_db.id}"]
  db_subnet_group_name   = aws_db_subnet_group.airflow[count.index].name

  final_snapshot_identifier = "${var.prefix}-airflow"

  copy_tags_to_snapshot          = true
  enable_global_write_forwarding = false
}

resource "aws_rds_cluster_instance" "airflow" {
  count              = var.airflow_on ? 1 : 0
  identifier         = "${var.prefix}-airflow"
  cluster_identifier = aws_rds_cluster.airflow[count.index].id
  engine             = aws_rds_cluster.airflow[count.index].engine
  engine_version     = aws_rds_cluster.airflow[count.index].engine_version
  instance_class     = var.airflow_db_instance_class
  promotion_tier     = 1
}

resource "aws_db_subnet_group" "airflow" {
  count      = var.airflow_on ? 1 : 0
  name       = "${var.prefix}-airflow"
  subnet_ids = aws_subnet.private_with_egress.*.id

  tags = {
    Name = "${var.prefix}-airflow"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "random_string" "aws_db_instance_airflow_password" {
  length  = 99
  special = false
}
