resource "aws_ecs_service" "arango" {
  count           = var.arango_on ? 1 : 0
  name            = "${var.prefix}-arango"
  cluster         = aws_ecs_cluster.main_cluster.id
  task_definition = aws_ecs_task_definition.arango_service[0].arn
  desired_count   = 1

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.arango_capacity_provider[0].name
    weight            = 100
    base              = 1
  }

  network_configuration {
    subnets         = [aws_subnet.datasets.*.id[0]]
    security_groups = [aws_security_group.arango_service[0].id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.arango[0].arn
    container_port   = "8529"
    container_name   = "arango"
  }

  service_registries {
    registry_arn = aws_service_discovery_service.arango[0].arn
  }

  depends_on = [
    # The target group must have been associated with the listener first
    "aws_lb_listener.arango",
    "aws_autoscaling_group.arango_service"
  ]
}

resource "aws_service_discovery_service" "arango" {
  count = var.arango_on ? 1 : 0
  name  = "${var.prefix}-arango"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.jupyterhub.id
    dns_records {
      ttl  = 10
      type = "A"
    }
  }
}

resource "aws_autoscaling_group" "arango_service" {
  count                     = var.arango_on ? 1 : 0
  name_prefix               = "${var.prefix}-arango"
  max_size                  = 1
  min_size                  = 1
  desired_capacity          = 1
  health_check_grace_period = 120
  health_check_type         = "EC2"
  vpc_zone_identifier       = ["${aws_subnet.datasets.*.id[0]}"]

  launch_template {
    id      = aws_launch_template.arango_service[0].id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.prefix}-arango-service"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_autoscaling_groups" "arango_asgs" {
  count = var.arango_on ? 1 : 0
  names = ["${aws_autoscaling_group.arango_service[0].name}"]
}

resource "aws_launch_template" "arango_service" {
  count         = var.arango_on ? 1 : 0
  name_prefix   = "${var.prefix}-arango-service-"
  image_id      = var.arango_image_id
  instance_type = var.arango_instance_type
  key_name      = aws_key_pair.shared.key_name

  metadata_options {
    http_tokens = "required"
  }

  network_interfaces {
    security_groups = [aws_security_group.arango-ec2[0].id]
    subnet_id       = aws_subnet.datasets.*.id[0]
  }
  iam_instance_profile {
    name = aws_iam_instance_profile.arango_ec2[0].name
  }

  user_data = (base64encode(templatefile("${path.module}/ecs_main_arango_user_data.sh",
    {
      ECS_CLUSTER   = aws_ecs_cluster.main_cluster.name
      EBS_REGION    = data.aws_region.aws_region.name
      EBS_VOLUME_ID = aws_ebs_volume.arango[0].id
  })))

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_ecs_capacity_provider" "arango_capacity_provider" {
  count = var.arango_on ? 1 : 0
  name  = "${var.prefix}-arango_service"
  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.arango_service[0].arn
    managed_scaling {
      maximum_scaling_step_size = 1000
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 3
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "arango" {
  count              = var.arango_on ? 1 : 0
  cluster_name       = aws_ecs_cluster.main_cluster.name
  capacity_providers = [aws_ecs_capacity_provider.arango_capacity_provider[0].name]
  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.arango_capacity_provider[0].name
  }
}

resource "aws_ecs_task_definition" "arango_service" {
  count  = var.arango_on ? 1 : 0
  family = "${var.prefix}-arango"
  container_definitions = templatefile("${path.module}/ecs_main_arango_container_definitions.json", {
    container_image = "${aws_ecr_repository.arango[0].repository_url}:latest"
    container_name  = "arango"
    log_group       = "${aws_cloudwatch_log_group.arango[0].name}"
    log_region      = "${data.aws_region.aws_region.name}"
    cpu             = "${local.arango_container_cpu}"
    memory          = "${local.arango_container_memory}"
    root_password   = "${random_string.aws_arangodb_root_password[0].result}"
  })

  execution_role_arn       = aws_iam_role.arango_task_execution[0].arn
  task_role_arn            = aws_iam_role.arango_task[0].arn
  network_mode             = "awsvpc"
  cpu                      = local.arango_container_cpu
  memory                   = local.arango_container_memory
  requires_compatibilities = ["EC2"]

  volume {
    name      = "data-arango"
    host_path = "/data/"
  }

  lifecycle {
    ignore_changes = [
      "revision",
    ]
  }
}

resource "aws_ebs_volume" "arango" {
  count             = var.arango_on ? 1 : 0
  availability_zone = var.aws_availability_zones[0]
  size              = var.arango_ebs_volume_size
  type              = var.arango_ebs_volume_type
  encrypted         = true

  lifecycle {
    prevent_destroy = false
  }

  tags = {
    Name = "${var.prefix}-arango"
  }
}

resource "aws_cloudwatch_log_group" "arango" {
  count             = var.arango_on ? 1 : 0
  name              = "${var.prefix}-arango"
  retention_in_days = "3653"
}

resource "aws_iam_role" "arango_task_execution" {
  count              = var.arango_on ? 1 : 0
  name               = "${var.prefix}-arango-task-execution"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.arango_task_execution_ecs_tasks_assume_role[0].json
}

data "aws_iam_policy_document" "arango_task_execution_ecs_tasks_assume_role" {
  count = var.arango_on ? 1 : 0
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "arango_task_execution" {
  count      = var.arango_on ? 1 : 0
  role       = aws_iam_role.arango_task_execution[0].name
  policy_arn = aws_iam_policy.arango_task_execution[0].arn
}

resource "aws_iam_policy" "arango_task_execution" {
  count  = var.arango_on ? 1 : 0
  name   = "${var.prefix}-arango-task-execution"
  path   = "/"
  policy = data.aws_iam_policy_document.arango_task_execution[0].json
}

data "aws_iam_policy_document" "arango_task_execution" {
  count = var.arango_on ? 1 : 0
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "${aws_cloudwatch_log_group.arango[0].arn}:*",
    ]
  }

  statement {
    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]

    resources = [
      "${aws_ecr_repository.arango[0].arn}",
    ]
  }

  statement {
    actions = [
      "ecr:GetAuthorizationToken",
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_role" "arango_task" {
  count              = var.arango_on ? 1 : 0
  name               = "${var.prefix}-arango-task"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.arango_task_ecs_tasks_assume_role[0].json
}

data "aws_iam_policy_document" "arango_task_ecs_tasks_assume_role" {
  count = var.arango_on ? 1 : 0
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "arango_ecs" {
  count              = var.arango_on ? 1 : 0
  name               = "${var.prefix}-arango-ecs"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.arango_ecs_assume_role[0].json
}

resource "aws_iam_role_policy_attachment" "arango_ecs" {
  count      = var.arango_on ? 1 : 0
  role       = aws_iam_role.arango_ecs[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}

data "aws_iam_policy_document" "arango_ecs_assume_role" {
  count = var.arango_on ? 1 : 0
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "arango_ec2" {
  count              = var.arango_on ? 1 : 0
  name               = "${var.prefix}-arango-ec2"
  assume_role_policy = data.aws_iam_policy_document.arango_ec2_assume_role[0].json
}

data "aws_iam_policy_document" "arango_ec2_assume_role" {
  count = var.arango_on ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "arango_ec2" {
  count      = var.arango_on ? 1 : 0
  role       = aws_iam_role.arango_ec2[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

data "aws_iam_policy_document" "arango_ebs" {
  count = var.arango_on ? 1 : 0
  # The Arango EC2 instance attaches the volume dynamically on startup via its userdata. To allow
  # this, it needs to be able to ec2:AttachVolume on both the EC2 instance and the volume. The
  # volume permission is fairly straightforward, but because the EC2 is launched by an autoscaling
  # group, there is no fixed ARN for the instance, so we use a condition on the instance profile as
  # the next best thing
  statement {
    effect = "Allow"
    actions = [
      "ec2:AttachVolume",
    ]
    resources = [
      "${aws_ebs_volume.arango[0].arn}"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "ec2:AttachVolume",
    ]
    resources = [
      "arn:aws:ec2:*:*:instance/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "ec2:InstanceProfile"
      values = [
        aws_iam_instance_profile.arango_ec2[0].arn,
      ]
    }
  }
}

resource "aws_iam_policy" "arango_ebs" {
  count       = var.arango_on ? 1 : 0
  name        = "${var.prefix}-arango-ebs"
  description = "enable-mounting-of-ebs-volume"
  policy      = data.aws_iam_policy_document.arango_ebs[0].json
}

resource "aws_iam_role_policy_attachment" "arango_ec2_ebs" {
  count      = var.arango_on ? 1 : 0
  role       = aws_iam_role.arango_ec2[0].name
  policy_arn = aws_iam_policy.arango_ebs[0].arn
}

resource "aws_iam_instance_profile" "arango_ec2" {
  count = var.arango_on ? 1 : 0
  name  = "${var.prefix}-arango-ec2"
  role  = aws_iam_role.arango_ec2[0].id
}

resource "aws_lb" "arango" {
  count                      = var.arango_on ? 1 : 0
  name                       = "${var.prefix}-arango"
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.arango_lb[0].id]
  enable_deletion_protection = true
  internal                   = true
  subnets                    = aws_subnet.datasets.*.id
  tags = {
    name = "arango-to-notebook-lb"
  }
}

resource "aws_lb_listener" "arango" {
  count             = var.arango_on ? 1 : 0
  load_balancer_arn = aws_lb.arango[0].arn
  port              = "8529"
  protocol          = "HTTPS"

  ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn = aws_acm_certificate_validation.arango[count.index].certificate_arn

  default_action {
    target_group_arn = aws_lb_target_group.arango[0].id
    type             = "forward"
  }
}

resource "aws_lb_target_group" "arango" {
  count       = var.arango_on ? 1 : 0
  name        = "${var.prefix}-arango"
  port        = "8529"
  vpc_id      = aws_vpc.datasets.id
  target_type = "ip"
  protocol    = "HTTP"

  health_check {
    protocol            = "HTTP"
    interval            = 10
    healthy_threshold   = 2
    unhealthy_threshold = 2
    path                = "/_db/_system/_admin/aardvark/index.html"
  }
}

resource "random_string" "aws_arangodb_root_password" {
  count   = var.arango_on ? 1 : 0
  length  = 64
  special = false

  lifecycle {
    ignore_changes = all
  }
}

resource "aws_backup_vault" "arango_backup_vault" {
  count = var.arango_on ? 1 : 0
  name  = "${var.prefix}-arangodb-backup-vault"
}

resource "aws_backup_plan" "arango_backup_plan" {
  count = var.arango_on ? 1 : 0
  name  = "${var.prefix}-arangodb-backup-plan"
  rule {
    rule_name         = "arangodb-backup-rule"
    target_vault_name = "${var.prefix}-arangodb-backup-vault"
    schedule          = "cron(0 0 * * ? *)"

    start_window      = 60
    completion_window = 360
    lifecycle {
      delete_after = 8
    }
  }

  depends_on = [aws_backup_vault.arango_backup_vault]
}

resource "aws_backup_selection" "arango_backup_resource" {
  count        = var.arango_on ? 1 : 0
  iam_role_arn = aws_iam_role.arango_ebs_backup[0].arn
  name         = "arangodb-backup-resources"
  plan_id      = aws_backup_plan.arango_backup_plan[0].id

  resources = [
    aws_ebs_volume.arango[0].arn
  ]
}

resource "aws_iam_role" "arango_ebs_backup" {
  count              = var.arango_on ? 1 : 0
  name               = "${var.prefix}-arango-ebs-backup"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.arango_ebs_backup_assume_role[0].json
}

data "aws_iam_policy_document" "arango_ebs_backup_assume_role" {
  count = var.arango_on ? 1 : 0
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "arango_ec2_ebs_backup" {
  count      = var.arango_on ? 1 : 0
  role       = aws_iam_role.arango_ebs_backup[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}
