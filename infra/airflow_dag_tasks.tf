resource "aws_ecs_cluster" "airflow_dag_tasks" {
  name = "${var.prefix}-airflow-dag-tasks"
}

resource "aws_ecs_task_definition" "airflow_dag_tasks" {
  count  = var.airflow_on ? 1 : 0
  family = "${var.prefix}-airflow-dag-tasks"
  container_definitions = templatefile(
    "${path.module}/airflow_dag_tasks_container_definitions.json", {
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

      datasets_db_host     = "${aws_rds_cluster.datasets.endpoint}"
      datasets_db_name     = "${aws_rds_cluster.datasets.database_name}"
      datasets_db_password = "${random_string.aws_rds_cluster_instance_datasets_password.result}"
      datasets_db_port     = "${aws_rds_cluster.datasets.port}"
      datasets_db_user     = "${var.datasets_rds_cluster_master_username}"

      sentry_dsn         = "${var.sentry_notebooks_dsn}"
      sentry_environment = "${var.sentry_environment}"

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

resource "aws_cloudwatch_log_group" "airflow_dag_tasks" {
  count             = var.airflow_on ? 1 : 0
  name              = "${var.prefix}-airflow-dag-tasks"
  retention_in_days = "3653"
}

resource "aws_cloudwatch_log_group" "airflow_dag_tasks_airflow_logging" {
  count             = var.airflow_on ? 1 : 0
  name              = "${var.prefix}-airflow-dag-tasks-airflow-logging"
  retention_in_days = "3653"
}
