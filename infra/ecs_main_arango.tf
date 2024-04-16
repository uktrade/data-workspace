resource "aws_ecs_service" "arango" {
  name            = "${var.prefix}-arango"
  cluster         = "${aws_ecs_cluster.main_cluster.id}"
  task_definition = "${aws_ecs_task_definition.arango_service.arn}"
  desired_count   = 1

  capacity_provider_strategy {
   capacity_provider = aws_ecs_capacity_provider.arango_capacity_provider.name
   weight            = 100
   base              = 1
 }

  network_configuration {
    subnets         = ["${aws_subnet.datasets.*.id[0]}"]
    security_groups = ["${aws_security_group.arango_service.id}"]
  }

  load_balancer {
    target_group_arn = "${aws_lb_target_group.arango.arn}"
    container_port   = "8529"
    container_name   = "arango"
  }

  service_registries {
    registry_arn = aws_service_discovery_service.arango.arn
  }

  depends_on = [
    # The target group must have been associated with the listener first
    "aws_lb_listener.arango",
    "aws_autoscaling_group.arango_service"
  ]
}

resource "aws_service_discovery_service" "arango" {
  name = "${var.prefix}-arango"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.jupyterhub.id
    dns_records {
      ttl  = 10
      type = "A"
    }
  }
}

resource "aws_autoscaling_group" "arango_service" {
  name_prefix               = "${var.prefix}-arango"
  max_size                  = 2
  min_size                  = 1
  desired_capacity          = 2
  health_check_grace_period = 120
  health_check_type         = "EC2"
  vpc_zone_identifier       = ["${aws_subnet.datasets.*.id[0]}"]

  launch_template {
    id                      = aws_launch_template.arango_service.id
    version                 = "$Latest"
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
  names = ["${aws_autoscaling_group.arango_service.name}"]
}

resource "aws_launch_template" "arango_service" {
  name_prefix = "${var.prefix}-arango-service-"
  image_id             = "ami-0c618421e207909d0"
  instance_type        = "t2.xlarge"
  key_name             = "${aws_key_pair.shared.key_name}"

  metadata_options {
    http_tokens        = "required"
  }

  network_interfaces {
    security_groups = ["${aws_security_group.arango-ec2.id}"]
    subnet_id       = aws_subnet.datasets.*.id[0]
    }
  
  iam_instance_profile {
    name = "${aws_iam_instance_profile.arango_ec2.name}"
    }

  user_data = "${data.template_file.ecs_config_template.rendered}"

  lifecycle {
    create_before_destroy = true
  }
}

data "template_file" "ecs_config_template" {
  template = "${filebase64("${path.module}/ecs_main_arango_user_data.sh")}"
  vars     = {
    ECS_CLUSTER = "${aws_ecs_cluster.main_cluster.name}"
    EBS_REGION  = "${data.aws_region.aws_region.name}"
    EBS_VOLUME_ID = "${aws_ebs_volume.arango.id}"
  }
  }

output "rendered"  {
  value = "${data.template_file.ecs_config_template.rendered}"
}

resource "aws_ecs_capacity_provider" "arango_capacity_provider" {
 name = "${var.prefix}-arango_service"

 auto_scaling_group_provider {
   auto_scaling_group_arn = aws_autoscaling_group.arango_service.arn

   managed_scaling {
     maximum_scaling_step_size = 1000
     minimum_scaling_step_size = 1
     status                    = "ENABLED"
     target_capacity           = 3
   }
 }
}

resource "aws_ecs_cluster_capacity_providers" "arango" {
 cluster_name = aws_ecs_cluster.main_cluster.name

 capacity_providers = [aws_ecs_capacity_provider.arango_capacity_provider.name]

 default_capacity_provider_strategy {
   capacity_provider = aws_ecs_capacity_provider.arango_capacity_provider.name
 }
}

resource "aws_ecs_task_definition" "arango_service" {
  family                   = "${var.prefix}-arango"
  container_definitions    = "${data.template_file.arango_service_container_definitions.rendered}"
  execution_role_arn       = "${aws_iam_role.arango_task_execution.arn}"
  task_role_arn            = "${aws_iam_role.arango_task.arn}"
  network_mode             = "awsvpc"
  cpu                      = "${local.arango_container_cpu}"
  memory                   = "${local.arango_container_memory}"
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

data "template_file" "arango_service_container_definitions" {
  template = "${file("${path.module}/ecs_main_arango_container_definitions.json")}"

  vars = {
    container_image = "339713044404.dkr.ecr.eu-west-2.amazonaws.com/data-workspace-dev-a-arango:latest"
    container_name  = "arango"
    log_group       = "${aws_cloudwatch_log_group.arango.name}"
    log_region      = "${data.aws_region.aws_region.name}"
    cpu             = "${local.arango_container_cpu}"
    memory          = "${local.arango_container_memory}"
    root_password   = "${random_string.aws_arangodb_root_password.result}"
  }
}

resource "aws_ebs_volume" "arango" {
  availability_zone = var.aws_availability_zones[0]
  size              = 20
  type              = "gp3"
  encrypted         = true

  lifecycle {
    prevent_destroy = false
  }

  tags = {
    Name = "${var.prefix}-arango"
  }
}

resource "aws_cloudwatch_log_group" "arango" {
  name              = "${var.prefix}-arango"
  retention_in_days = "3653"
}

resource "aws_iam_role" "arango_task_execution" {
  name               = "${var.prefix}-arango-task-execution"
  path               = "/"
  assume_role_policy = "${data.aws_iam_policy_document.arango_task_execution_ecs_tasks_assume_role.json}"
}

data "aws_iam_policy_document" "arango_task_execution_ecs_tasks_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "arango_task_execution" {
  role       = "${aws_iam_role.arango_task_execution.name}"
  policy_arn = "${aws_iam_policy.arango_task_execution.arn}"
}

resource "aws_iam_policy" "arango_task_execution" {
  name   = "${var.prefix}-arango-task-execution"
  path   = "/"
  policy = "${data.aws_iam_policy_document.arango_task_execution.json}"
}

data "aws_iam_policy_document" "arango_task_execution" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "${aws_cloudwatch_log_group.arango.arn}:*",
    ]
  }

  statement {
    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]

    resources = [
      "${aws_ecr_repository.arango.arn}",
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
  name               = "${var.prefix}-arango-task"
  path               = "/"
  assume_role_policy = "${data.aws_iam_policy_document.arango_task_ecs_tasks_assume_role.json}"
}

data "aws_iam_policy_document" "arango_task_ecs_tasks_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "arango_ecs" {
  name               = "${var.prefix}-arango-ecs"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.arango_ecs_assume_role.json
}

resource "aws_iam_role_policy_attachment" "arango_ecs" {
  role       = aws_iam_role.arango_ecs.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}

data "aws_iam_policy_document" "arango_ecs_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "arango_ec2" {
  name               = "${var.prefix}-arango-ec2"
  assume_role_policy = data.aws_iam_policy_document.arango_ec2_assume_role.json
}

data "aws_iam_policy_document" "arango_ec2_assume_role" {

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "arango_ec2" {
  role       = aws_iam_role.arango_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "arango_ec2_ssm" {
  role        = aws_iam_role.arango_ec2.name
  policy_arn  = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "arango_ebs" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:AttachVolume",
      "ec2:CreateVolume",
      "ec2:CreateSnapshot",
      "ec2:CreateTags",
      "ec2:DeleteVolume",
      "ec2:DeleteSnapshot",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeInstances",
      "ec2:DescribeVolumes",
      "ec2:DescribeVolumeAttribute",
      "ec2:DescribeVolumeStatus",
      "ec2:DescribeSnapshots",
      "ec2:CopySnapshot",
      "ec2:DescribeSnapshotAttribute",
      "ec2:DetachVolume",
      "ec2:ModifySnapshotAttribute",
      "ec2:ModifyVolumeAttribute",
      "ec2:DescribeTags"
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "arango_ebs" {
  name        = "arango-ebs"
  description = "enable-mounting-of-ebs-volume"
  policy      = data.aws_iam_policy_document.arango_ebs.json
}

resource "aws_iam_role_policy_attachment" "arango_ec2_ebs" {
  role        = aws_iam_role.arango_ec2.name
  policy_arn  = aws_iam_policy.arango_ebs.arn
}

resource "aws_iam_instance_profile" "arango_ec2" {
  name  = "${var.prefix}-arango-ec2"
  role  = aws_iam_role.arango_ec2.id
}

resource "aws_lb" "arango" {
  name               = "${var.prefix}-arango"
  load_balancer_type = "application"
  security_groups = ["${aws_security_group.arango_lb.id}"]
  enable_deletion_protection = true
  internal                   = true
  subnets = aws_subnet.datasets.*.id
  timeouts {}

  tags = {
    name = "arango-to-notebook-lb"
  }
}

resource "aws_lb_listener" "arango" {
  load_balancer_arn = "${aws_lb.arango.arn}"
  port              = "8529"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_lb_target_group.arango.id}"
    type             = "forward"
  }
}

resource "aws_lb_target_group" "arango" {
  name = "${var.prefix}-arango"
  port        = "8529"
  vpc_id      = "${aws_vpc.datasets.id}"
  target_type = "ip"
  protocol    = "HTTP"

  health_check {
    protocol = "HTTP"
    interval = 10
    healthy_threshold   = 2
    unhealthy_threshold = 2
    path = "/_db/_system/_admin/aardvark/index.html"
  }
}

resource "random_string" "aws_arangodb_root_password" {
  length  = 64
  special = false

  lifecycle {
    ignore_changes = all
  }
}