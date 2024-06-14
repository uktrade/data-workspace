resource "aws_ecs_service" "airflow_scheduler" {
  count                      = var.airflow_on ? 1 : 0
  name                       = "${var.prefix}-airflow-scheduler"
  cluster                    = aws_ecs_cluster.main_cluster.id
  task_definition            = aws_ecs_task_definition.airflow_scheduler[count.index].arn
  desired_count              = 1
  launch_type                = "FARGATE"
  deployment_maximum_percent = 200
  platform_version           = "1.4.0"

  network_configuration {
    subnets         = ["${aws_subnet.private_with_egress.*.id[0]}"]
    security_groups = ["${aws_security_group.airflow_webserver.id}"]
  }
}

resource "aws_ecs_task_definition" "airflow_scheduler" {
  count  = var.airflow_on ? 1 : 0
  family = "${var.prefix}-airflow-scheduler"
  container_definitions = templatefile(
    "${path.module}/airflow_scheduler_container_definitions.json", {
      command = "[\"/home/vcap/app/dataflow/bin/airflow-scheduler.sh\"]"

      container_image = "${aws_ecr_repository.airflow.repository_url}:master"
      container_name  = "airflow"
      log_group       = "${aws_cloudwatch_log_group.airflow_webserver[count.index].name}"
      log_region      = "${data.aws_region.aws_region.name}"
      cpu             = "${local.airflow_container_cpu}"
      memory          = "${local.airflow_container_memory}"

      db_host     = "${aws_rds_cluster.airflow[count.index].endpoint}"
      db_name     = "${aws_rds_cluster.airflow[count.index].database_name}"
      db_password = "${random_string.aws_db_instance_airflow_password.result}"
      db_port     = "${aws_rds_cluster.airflow[count.index].port}"
      db_user     = "${aws_rds_cluster.airflow[count.index].master_username}"
      secret_key  = "${random_string.airflow_secret_key.result}"

      datasets_db_host     = "${aws_rds_cluster.datasets.endpoint}"
      datasets_db_name     = "${aws_rds_cluster.datasets.database_name}"
      datasets_db_password = "${random_string.aws_rds_cluster_instance_datasets_password.result}"
      datasets_db_port     = "${aws_rds_cluster.datasets.port}"
      datasets_db_user     = "${var.datasets_rds_cluster_master_username}"

      sentry_dsn         = "${var.sentry_notebooks_dsn}"
      sentry_environment = "${var.sentry_environment}"

      authbroker_url           = "${var.airflow_authbroker_url}"
      authbroker_client_id     = "${var.airflow_authbroker_client_id}"
      authbroker_client_secret = "${var.airflow_authbroker_client_secret}"

      subnets         = "${aws_subnet.private_with_egress.*.id[0]}"
      security_groups = "${aws_security_group.airflow_webserver.id}"
      task_definition = "${aws_ecs_task_definition.airflow_dag_tasks[0].arn}"
      cluster         = "${aws_ecs_cluster.airflow_dag_tasks.name}"

      cloudwatch_log_group_arn = "${aws_cloudwatch_log_group.airflow_dag_tasks_airflow_logging[0].arn}"
    }
  )
  execution_role_arn       = aws_iam_role.airflow_webserver_execution[count.index].arn
  task_role_arn            = aws_iam_role.airflow_webserver_task[count.index].arn
  network_mode             = "awsvpc"
  cpu                      = local.airflow_container_cpu
  memory                   = local.airflow_container_memory
  requires_compatibilities = ["FARGATE"]

  lifecycle {
    ignore_changes = [
      "revision",
    ]
  }
}

resource "aws_cloudwatch_log_group" "airflow_scheduler" {
  count             = var.airflow_on ? 1 : 0
  name              = "${var.prefix}-airflow-scheduler"
  retention_in_days = "3653"
}