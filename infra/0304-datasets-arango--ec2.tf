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

  user_data = base64encode(<<-EOT
      #!/bin/bash
      # install and start ecs agent

      EC2_INSTANCE_ID=$(ec2-metadata --instance-id | sed 's/instance-id: //')
      aws ec2 attach-volume --volume-id ${aws_ebs_volume.arango[0].id} --instance-id $EC2_INSTANCE_ID --device /dev/xvdf --region ${data.aws_region.aws_region.name}
      # Follow symlinks to find the real device
      device=$(sudo readlink -f /dev/xvdf)
        # Wait for the drive to be attached
      while [ ! -e $device ] ; do sleep 1 ; done
      # Format /dev/sdh if it does not contain a partition yet
      if [ "$(sudo file -b -s $device)" == "data" ]; then
      sudo mkfs -t ext4 $device
      fi
      # Mount the drive
      sudo mkdir -p /data
      sudo mount $device /data

      mkdir -p /etc/ecs/
      echo "ECS_CLUSTER=${aws_ecs_cluster.main_cluster.name}" >> /etc/ecs/ecs.config
      sudo systemctl enable --now --no-block ecs
    EOT
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudwatch_log_group" "arango" {
  count             = var.arango_on ? 1 : 0
  name              = "${var.prefix}-arango"
  retention_in_days = "3653"
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
