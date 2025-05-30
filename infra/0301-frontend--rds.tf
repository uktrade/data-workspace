resource "aws_db_instance" "admin" {
  identifier = "${var.prefix}-admin"

  allocated_storage           = var.admin_db_instance_allocated_storage
  max_allocated_storage       = var.admin_db_instance_max_allocated_storage
  storage_type                = "gp2"
  engine                      = "postgres"
  engine_version              = var.admin_db_instance_version
  instance_class              = var.admin_db_instance_class
  allow_major_version_upgrade = true

  apply_immediately = true

  backup_retention_period = 31
  backup_window           = "03:29-03:59"

  db_name  = "jupyterhub_admin"
  username = "jupyterhub_admin_master"
  password = random_string.aws_db_instance_admin_password.result

  final_snapshot_identifier = "${var.prefix}-admin-final-snapshot"
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

resource "aws_db_subnet_group" "admin" {
  name       = "${var.prefix}-admin"
  subnet_ids = aws_subnet.private_with_egress.*.id

  tags = {
    Name = "${var.prefix}-admin"
  }
}

resource "random_string" "aws_db_instance_admin_password" {
  length  = 128
  special = false
}
