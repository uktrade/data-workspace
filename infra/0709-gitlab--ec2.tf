resource "aws_iam_role" "gitlab_ec2" {
  count              = var.gitlab_on ? 1 : 0
  name               = "${var.prefix}-gitlab-ec2"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.gitlab_ec2_assume_role[count.index].json
}

data "aws_iam_policy_document" "gitlab_ec2_assume_role" {
  count = var.gitlab_on ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "gitlab_ec2" {
  count      = var.gitlab_on ? 1 : 0
  role       = aws_iam_role.gitlab_ec2[count.index].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "gitlab_ec2" {
  count = var.gitlab_on ? 1 : 0
  name  = "${var.prefix}-gitlab-ec2"
  path  = "/"
  role  = aws_iam_role.gitlab_ec2[count.index].id
}

resource "aws_instance" "gitlab" {
  count                = var.gitlab_on ? 1 : 0
  ami                  = "ami-0749bd3fac17dc2cc"
  instance_type        = var.gitlab_instance_type
  iam_instance_profile = aws_iam_instance_profile.gitlab_ec2[count.index].id
  availability_zone    = var.aws_availability_zones[0]

  vpc_security_group_ids      = ["${aws_security_group.gitlab-ec2[count.index].id}"]
  associate_public_ip_address = "false"
  key_name                    = aws_key_pair.shared.key_name

  subnet_id = aws_subnet.private_with_egress.*.id[0]
  user_data = <<EOF
  #!/bin/bash
  echo ECS_CLUSTER=${aws_ecs_cluster.main_cluster.id} >> /etc/ecs/ecs.config

  # Follow symlinks to find the real device
  device=$(sudo readlink -f /dev/sdh)

  # Wait for the drive to be attached
  while [ ! -e $device ] ; do sleep 1 ; done

  # Format /dev/sdh if it does not contain a partition yet
  if [ "$(sudo file -b -s $device)" == "data" ]; then
    sudo mkfs -t ext4 $device
  fi

  # Mount the drive
  sudo mkdir -p /data
  sudo mount $device /data

  # Persist the volume in /etc/fstab so it gets mounted again
  sudo echo "$device /data ext4 defaults,nofail 0 2" >> /etc/fstab

  sudo mkdir -p /data/gitlab
  EOF

  tags = {
    Name = "${var.prefix}-gitlab"
  }
}

resource "aws_volume_attachment" "gitlab" {
  count       = var.gitlab_on ? 1 : 0
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.gitlab[count.index].id
  instance_id = aws_instance.gitlab[count.index].id
}
