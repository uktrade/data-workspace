resource "aws_db_instance" "sagemaker" {
  identifier = "${var.prefix}-sagemaker"

  allocated_storage     = var.sagemaker_db_instance_allocated_storage
  max_allocated_storage = var.sagemaker_db_instance_max_allocated_storage
  storage_type          = "gp2"
  engine                = "postgres"
  engine_version        = var.sagemaker_db_instance_version
  instance_class        = var.sagemaker_db_instance_class //"t4g.micro"

  apply_immediately = true

  backup_retention_period = 31
  backup_window           = "03:29-03:59"

  db_name  = "sagemaker"
  username = "sagemaker_master"
  password = random_string.aws_db_instance_admin_password.result

  final_snapshot_identifier = "${var.prefix}-sagemaker-final-snapshot"
  copy_tags_to_snapshot     = true

  vpc_security_group_ids = ["${aws_security_group.admin_db.id}"]
  db_subnet_group_name   = aws_db_subnet_group.admin.name

  performance_insights_enabled = true
  storage_encrypted            = true

  lifecycle {
    ignore_changes = [
      snapshot_identifier,
      final_snapshot_identifier,
      engine_version,
    ]
  }
}
