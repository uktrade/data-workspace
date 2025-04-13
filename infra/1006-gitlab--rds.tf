resource "aws_rds_cluster" "gitlab" {
  count                   = var.gitlab_on ? 1 : 0
  cluster_identifier      = "${var.prefix}-gitlab"
  engine                  = "aurora-postgresql"
  availability_zones      = var.aws_availability_zones
  database_name           = "${var.prefix_underscore}_gitlab"
  master_username         = "${var.prefix_underscore}_gitlab_master"
  master_password         = random_string.aws_db_instance_gitlab_password.result
  backup_retention_period = 31
  preferred_backup_window = "03:29-03:59"
  apply_immediately       = true

  vpc_security_group_ids = ["${aws_security_group.gitlab_db[count.index].id}"]
  db_subnet_group_name   = aws_db_subnet_group.gitlab[count.index].name
  #ca_cert_identifier     = "rds-ca-2019"

  copy_tags_to_snapshot          = true
  enable_global_write_forwarding = false
  timeouts {}

  lifecycle {
    ignore_changes = [
      engine_version,
    ]
  }
}

resource "aws_rds_cluster_instance" "gitlab" {
  count              = var.gitlab_on ? 1 : 0
  identifier         = var.gitlab_rds_cluster_instance_identifier != "" ? var.gitlab_rds_cluster_instance_identifier : "${var.prefix}-gitlab-writer"
  cluster_identifier = aws_rds_cluster.gitlab[count.index].id
  engine             = aws_rds_cluster.gitlab[count.index].engine
  engine_version     = aws_rds_cluster.gitlab[count.index].engine_version
  instance_class     = var.gitlab_db_instance_class
  promotion_tier     = 1

}

resource "aws_db_subnet_group" "gitlab" {
  count      = var.gitlab_on ? 1 : 0
  name       = "${var.prefix}-gitlab"
  subnet_ids = aws_subnet.private_with_egress.*.id

  tags = {
    Name = "${var.prefix}-gitlab"
  }
}


resource "random_string" "aws_db_instance_gitlab_password" {
  length  = 99
  special = false
}