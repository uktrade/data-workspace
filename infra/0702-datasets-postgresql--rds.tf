resource "aws_rds_cluster" "datasets" {
  availability_zones              = var.aws_availability_zones
  backup_retention_period         = var.datasets_rds_cluster_backup_retention_period
  cluster_identifier              = var.datasets_rds_cluster_cluster_identifier
  database_name                   = var.datasets_rds_cluster_database_name
  db_subnet_group_name            = aws_db_subnet_group.datasets.name
  engine                          = var.datasets_rds_cluster_database_engine
  master_password                 = random_string.aws_rds_cluster_instance_datasets_password.result
  master_username                 = var.datasets_rds_cluster_master_username
  storage_encrypted               = var.datasets_rds_cluster_storage_encryption_enabled
  vpc_security_group_ids          = ["${aws_security_group.datasets.id}"]
  skip_final_snapshot             = true
  deletion_protection             = true
  enabled_cloudwatch_logs_exports = ["postgresql"]

  timeouts {}
  lifecycle {
    ignore_changes = [master_password, engine_version]
  }
}

resource "aws_rds_cluster_instance" "datasets" {
  cluster_identifier           = aws_rds_cluster.datasets.cluster_identifier
  db_subnet_group_name         = aws_db_subnet_group.datasets.name
  engine                       = var.datasets_rds_cluster_database_engine
  identifier                   = var.datasets_rds_cluster_instance_identifier
  instance_class               = var.datasets_rds_cluster_instance_class
  performance_insights_enabled = var.datasets_rds_cluster_instance_performance_insights_enabled
  promotion_tier               = 1
  db_parameter_group_name      = var.datasets_rds_cluster_instance_parameter_group
  monitoring_interval          = var.datasets_rds_cluster_instance_monitoring_interval

  lifecycle {
    ignore_changes = [engine_version]
  }
}

resource "aws_db_subnet_group" "datasets" {
  name       = "${var.prefix}-datasets"
  subnet_ids = aws_subnet.datasets.*.id

  tags = {
    Name = "${var.prefix}-datasets"
  }
}

resource "random_string" "aws_rds_cluster_instance_datasets_password" {
  length  = 64
  special = false

  lifecycle {
    ignore_changes = all
  }
}

resource "aws_security_group_rule" "admin_service_egress_postgres_to_datasets_db" {
  description = "egress-postgres-to-datasets-db"

  security_group_id        = aws_security_group.admin_service.id
  source_security_group_id = aws_security_group.datasets.id

  type      = "egress"
  from_port = aws_rds_cluster_instance.datasets.port
  to_port   = aws_rds_cluster_instance.datasets.port
  protocol  = "tcp"
}

resource "aws_security_group_rule" "notebooks_egress_postgres_to_datasets_db" {
  description = "egress-postgres-to-datasets-db"

  security_group_id        = aws_security_group.notebooks.id
  source_security_group_id = aws_security_group.datasets.id

  type      = "egress"
  from_port = aws_rds_cluster_instance.datasets.port
  to_port   = aws_rds_cluster_instance.datasets.port
  protocol  = "tcp"
}


resource "aws_security_group_rule" "datasets_db_ingress_postgres_from_airflow_dag_processor" {
  description = "ingress-postgres-from-airflow"

  security_group_id        = aws_security_group.datasets.id
  source_security_group_id = aws_security_group.airflow_dag_processor_service.id

  type      = "ingress"
  from_port = aws_rds_cluster_instance.datasets.port
  to_port   = aws_rds_cluster_instance.datasets.port
  protocol  = "tcp"
}

resource "aws_security_group" "datasets" {
  name        = "${var.prefix}-datasets"
  description = "${var.prefix}-datasets"
  vpc_id      = aws_vpc.datasets.id

  tags = {
    Name = "${var.prefix}-datasets"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "datasets_db_ingress_postgres_from_admin" {
  description = "ingress-postgres-from-admin"

  security_group_id        = aws_security_group.datasets.id
  source_security_group_id = aws_security_group.admin_service.id

  type      = "ingress"
  from_port = aws_rds_cluster_instance.datasets.port
  to_port   = aws_rds_cluster_instance.datasets.port
  protocol  = "tcp"
}

resource "aws_security_group_rule" "datasets_db_ingress_postgres_from_notebooks" {
  description = "ingress-postgres-from-notebooks"

  security_group_id        = aws_security_group.datasets.id
  source_security_group_id = aws_security_group.notebooks.id

  type      = "ingress"
  from_port = aws_rds_cluster_instance.datasets.port
  to_port   = aws_rds_cluster_instance.datasets.port
  protocol  = "tcp"
}

resource "aws_security_group_rule" "datasets_db_ingress_postgres_from_superset" {
  description = "ingress-postgres-from-superset"

  security_group_id        = aws_security_group.datasets.id
  source_security_group_id = aws_security_group.superset_service.id

  type      = "ingress"
  from_port = aws_rds_cluster_instance.datasets.port
  to_port   = aws_rds_cluster_instance.datasets.port
  protocol  = "tcp"
}

resource "aws_security_group_rule" "superset_service_egress_postgres_datasets_db" {
  description = "egress-postgres-datasets-db"

  security_group_id        = aws_security_group.superset_service.id
  source_security_group_id = aws_security_group.datasets.id

  type      = "egress"
  from_port = "5432"
  to_port   = "5432"
  protocol  = "tcp"
}