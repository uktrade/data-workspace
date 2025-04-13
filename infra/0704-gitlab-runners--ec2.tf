resource "aws_autoscaling_group" "gitlab_runner" {
  count                     = var.gitlab_on ? 1 : 0
  name_prefix               = "${var.prefix}-gitlab-runner-"
  max_size                  = 2
  min_size                  = 1
  desired_capacity          = 1
  health_check_grace_period = 120
  health_check_type         = "EC2"
  launch_configuration      = aws_launch_configuration.gitlab_runner[count.index].name
  vpc_zone_identifier       = aws_subnet.private_without_egress.*.id
  force_delete_warm_pool    = false
  timeouts {}

  tag {
    key                 = "Name"
    value               = "${var.prefix}-gitlab-runner-asg"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_configuration" "gitlab_runner" {
  count       = var.gitlab_on ? 1 : 0
  name_prefix = "${var.prefix}-gitlab-runner-"
  # This is the ECS optimized image, although we're not running ECS. It's
  # handy since it has everything docker installed, and cuts down on the
  # types of infrastructure
  image_id             = "ami-0749bd3fac17dc2cc"
  instance_type        = var.gitlab_runner_instance_type
  iam_instance_profile = aws_iam_instance_profile.gitlab_runner[count.index].name
  security_groups      = ["${aws_security_group.gitlab_runner[count.index].id}"]
  key_name             = aws_key_pair.shared.key_name

  associate_public_ip_address = false

  lifecycle {
    create_before_destroy = true
  }

  root_block_device {
    volume_size = var.gitlab_runner_root_volume_size
    encrypted   = true
  }

  user_data = <<EOF
  #!/bin/bash
  #
  set -e
  yum update -y
  yum install -y git jq unzip

  curl "https://s3.eu-west-2.amazonaws.com/mirrors.notebook.uktrade.io/aws-cli/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip awscliv2.zip
  ./aws/install

  curl -L --output /usr/local/bin/gitlab-runner https://s3.eu-west-2.amazonaws.com/mirrors.notebook.uktrade.io/gitlab-runner/gitlab-runner-linux-amd64
  chmod +x /usr/local/bin/gitlab-runner
  ln -s /usr/local/bin/gitlab-runner /usr/bin/gitlab-runner
  useradd --comment 'GitLab Runner' --create-home gitlab-runner --shell /bin/bash
  usermod -aG docker gitlab-runner

  mkdir -p /etc/gitlab-runner
  echo "concurrent = 10" >> /etc/gitlab-runner/config.toml
  echo "check_interval = 1" >> /etc/gitlab-runner/config.toml

  echo "0 0 * * * /usr/bin/docker image prune -f -a --filter until=168h" >> /var/spool/cron/ec2-user

  gitlab-runner install --user=gitlab-runner --working-directory=/home/gitlab-runner
  gitlab-runner start
  # Connects via HTTP, but uses private ip, not public internet
  gitlab-runner register \
    --non-interactive \
    --url "http://${var.gitlab_domain}/" \
    --registration-token "${var.gitlab_runner_visualisations_deployment_project_token}" \
    --executor "shell" \
    --description "visualisations-deployment" \
    --access-level "not_protected" \
    --run-untagged="true" \
    --locked="true"
  EOF
}

resource "aws_autoscaling_group" "gitlab_runner_tap" {
  count                     = var.gitlab_on ? 1 : 0
  name_prefix               = "${var.prefix}-gitlab-runner-tap-"
  max_size                  = 2
  min_size                  = 1
  desired_capacity          = 1
  health_check_grace_period = 120
  health_check_type         = "EC2"
  launch_configuration      = aws_launch_configuration.gitlab_runner_tap[count.index].name
  vpc_zone_identifier       = aws_subnet.private_without_egress.*.id

  tag {
    key                 = "Name"
    value               = "${var.prefix}-gitlab-runner-tap-asg"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_configuration" "gitlab_runner_tap" {
  count       = var.gitlab_on ? 1 : 0
  name_prefix = "${var.prefix}-gitlab-runner-tap-"
  # This is the ECS optimized image, although we're not running ECS. It's
  # handy since it has everything docker installed, and cuts down on the
  # types of infrastructure
  image_id             = "ami-0749bd3fac17dc2cc"
  instance_type        = var.gitlab_runner_tap_instance_type
  iam_instance_profile = aws_iam_instance_profile.gitlab_runner[count.index].name
  security_groups      = ["${aws_security_group.gitlab_runner[count.index].id}"]
  key_name             = aws_key_pair.shared.key_name

  associate_public_ip_address = false

  lifecycle {
    create_before_destroy = true
  }

  root_block_device {
    volume_size = var.gitlab_runner_team_root_volume_size
    encrypted   = true
  }

  user_data = <<EOF
  #!/bin/bash
  #
  set -e
  yum update -y
  yum install -y git jq unzip

  curl "https://s3.eu-west-2.amazonaws.com/mirrors.notebook.uktrade.io/aws-cli/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip awscliv2.zip
  ./aws/install

  curl -L --output /usr/local/bin/gitlab-runner https://s3.eu-west-2.amazonaws.com/mirrors.notebook.uktrade.io/gitlab-runner/gitlab-runner-linux-amd64
  chmod +x /usr/local/bin/gitlab-runner
  ln -s /usr/local/bin/gitlab-runner /usr/bin/gitlab-runner
  useradd --comment 'GitLab Runner' --create-home gitlab-runner --shell /bin/bash
  usermod -aG docker gitlab-runner

  mkdir -p /etc/gitlab-runner
  echo "concurrent = 10" >> /etc/gitlab-runner/config.toml
  echo "check_interval = 1" >> /etc/gitlab-runner/config.toml

  echo "0 0 * * * /usr/bin/docker image prune -f -a --filter until=168h" >> /var/spool/cron/ec2-user

  gitlab-runner install --user=gitlab-runner --working-directory=/home/gitlab-runner
  gitlab-runner start
  # Connects via HTTP, but uses private ip, not public internet
  gitlab-runner register \
    --non-interactive \
    --url "http://${var.gitlab_domain}/" \
    --clone-url "http://${var.gitlab_domain}/" \
    --registration-token "${var.gitlab_runner_tap_project_token}" \
    --executor "shell" \
    --description "tap" \
    --access-level "not_protected" \
    --run-untagged="true" \
    --locked="true"
  EOF
}

resource "aws_autoscaling_group" "gitlab_runner_data_science" {
  count                     = var.gitlab_on ? 1 : 0
  name_prefix               = "${var.prefix}-gitlab-runner-data-science-"
  max_size                  = 2
  min_size                  = 1
  desired_capacity          = 1
  health_check_grace_period = 120
  health_check_type         = "EC2"
  launch_configuration      = aws_launch_configuration.gitlab_runner_data_science[0].name
  vpc_zone_identifier       = aws_subnet.private_without_egress.*.id

  tag {
    key                 = "Name"
    value               = "${var.prefix}-gitlab-runner-data-science-asg"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_configuration" "gitlab_runner_data_science" {
  count       = var.gitlab_on ? 1 : 0
  name_prefix = "${var.prefix}-gitlab-runner-data-science-"
  # This is the ECS optimized image, although we're not running ECS. It's
  # handy since it has everything docker installed, and cuts down on the
  # types of infrastructure
  image_id             = "ami-0749bd3fac17dc2cc"
  instance_type        = var.gitlab_runner_data_science_instance_type
  iam_instance_profile = aws_iam_instance_profile.gitlab_runner_data_science[count.index].name
  security_groups      = ["${aws_security_group.gitlab_runner[count.index].id}"]
  key_name             = aws_key_pair.shared.key_name

  associate_public_ip_address = false

  lifecycle {
    create_before_destroy = true
  }

  root_block_device {
    volume_size = var.gitlab_runner_team_root_volume_size
    encrypted   = true
  }

  user_data = <<EOF
  #!/bin/bash
  #
  set -e
  yum update -y
  yum install -y git jq unzip

  curl "https://s3.eu-west-2.amazonaws.com/mirrors.notebook.uktrade.io/aws-cli/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip awscliv2.zip
  ./aws/install

  curl -L --output /usr/local/bin/gitlab-runner https://s3.eu-west-2.amazonaws.com/mirrors.notebook.uktrade.io/gitlab-runner/gitlab-runner-linux-amd64
  chmod +x /usr/local/bin/gitlab-runner
  ln -s /usr/local/bin/gitlab-runner /usr/bin/gitlab-runner
  useradd --comment 'GitLab Runner' --create-home gitlab-runner --shell /bin/bash
  usermod -aG docker gitlab-runner

  mkdir -p /etc/gitlab-runner
  echo "concurrent = 10" >> /etc/gitlab-runner/config.toml
  echo "check_interval = 1" >> /etc/gitlab-runner/config.toml

  echo "0 0 * * * /usr/bin/docker image prune -f -a --filter until=168h" >> /var/spool/cron/ec2-user

  gitlab-runner install --user=gitlab-runner --working-directory=/home/gitlab-runner
  gitlab-runner start
  # Connects via HTTP, but uses private ip, not public internet
  gitlab-runner register \
    --non-interactive \
    --url "http://${var.gitlab_domain}/" \
    --clone-url "http://${var.gitlab_domain}/" \
    --registration-token "${var.gitlab_runner_data_science_project_token}" \
    --executor "shell" \
    --description "data science" \
    --access-level "not_protected" \
    --run-untagged="true" \
    --locked="true"
  EOF
}

resource "aws_iam_instance_profile" "gitlab_runner" {
  count = var.gitlab_on ? 1 : 0
  name  = "${var.prefix}-gitlab-runner"
  role  = aws_iam_role.gitlab_runner[count.index].name
}

resource "aws_iam_role" "gitlab_runner" {
  count              = var.gitlab_on ? 1 : 0
  name               = "${var.prefix}-gitlab-runner"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.gitlab_runner_assume_role[count.index].json
}

data "aws_iam_policy_document" "gitlab_runner_assume_role" {
  count = var.gitlab_on ? 1 : 0
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "gitlab_runner" {
  count  = var.gitlab_on ? 1 : 0
  name   = "${var.prefix}-gitlab-runner"
  policy = data.aws_iam_policy_document.gitlab_runner[count.index].json
}

data "aws_iam_policy_document" "gitlab_runner" {
  count = var.gitlab_on ? 1 : 0

  statement {
    actions = [
      "ecr:GetAuthorizationToken",
    ]

    resources = [
      "*"
    ]
  }

  # Read only for the base images
  statement {
    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]

    resources = concat([
      "${aws_ecr_repository.visualisation_base.arn}",
    ], [for i, tool in var.tools : "${aws_ecr_repository.tools[i].arn}"])
  }

  # All for user-provided
  statement {
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:DescribeImages",
      "ecr:BatchGetImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage",
    ]
    resources = [
      "${aws_ecr_repository.user_provided.arn}",
    ]
  }
}

resource "aws_iam_policy_attachment" "gitlab_runner" {
  count      = var.gitlab_on ? 1 : 0
  name       = "${var.prefix}-gitlab-runner"
  roles      = ["${aws_iam_role.gitlab_runner[count.index].name}"]
  policy_arn = aws_iam_policy.gitlab_runner[count.index].arn
}

resource "aws_iam_instance_profile" "gitlab_runner_data_science" {
  count = var.gitlab_on ? 1 : 0
  name  = "${var.prefix}-gitlab-runner-data-science"
  role  = aws_iam_role.gitlab_runner_data_science[count.index].name
}

resource "aws_iam_role" "gitlab_runner_data_science" {
  count              = var.gitlab_on ? 1 : 0
  name               = "${var.prefix}-gitlab-runner-data-science"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.gitlab_runner_data_science_assume_role[count.index].json
}

data "aws_iam_policy_document" "gitlab_runner_data_science_assume_role" {
  count = var.gitlab_on ? 1 : 0
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "gitlab_runner_data_science" {
  count  = var.gitlab_on ? 1 : 0
  name   = "${var.prefix}-gitlab-runner-data-science"
  policy = data.aws_iam_policy_document.gitlab_runner_data_science[count.index].json
}

data "aws_iam_policy_document" "gitlab_runner_data_science" {
  count = var.gitlab_on ? 1 : 0

  statement {
    actions = [
      "ecr:GetAuthorizationToken",
    ]

    resources = [
      "*"
    ]
  }

  # Read only for the base images
  statement {
    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]

    resources = concat([
      "${aws_ecr_repository.visualisation_base.arn}",
    ], [for i, tool in var.tools : "${aws_ecr_repository.tools[i].arn}"])
  }

  # Allow list and put object for Gitlab private package index
  statement {
    actions = [
      "s3:ListBucket",
    ]
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.notebooks.id}",
    ]
  }

  statement {
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.notebooks.id}/shared/ddat_packages/*"
    ]
  }
}

resource "aws_iam_policy_attachment" "gitlab_runner_data_science" {
  count      = var.gitlab_on ? 1 : 0
  name       = "${var.prefix}-gitlab-runner-data-science"
  roles      = ["${aws_iam_role.gitlab_runner_data_science[count.index].name}"]
  policy_arn = aws_iam_policy.gitlab_runner_data_science[count.index].arn
}

resource "aws_autoscaling_group" "gitlab_runner_ag_data_science" {
  count                     = var.gitlab_on ? 1 : 0
  name_prefix               = "${var.prefix}-gitlab-runner-ag-data-science-"
  max_size                  = 2
  min_size                  = 1
  desired_capacity          = 1
  health_check_grace_period = 120
  health_check_type         = "EC2"
  launch_configuration      = aws_launch_configuration.gitlab_runner_ag_data_science[0].name
  vpc_zone_identifier       = aws_subnet.private_without_egress.*.id

  tag {
    key                 = "Name"
    value               = "${var.prefix}-gitlab-runner-ag-data-science-asg"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_configuration" "gitlab_runner_ag_data_science" {
  count       = var.gitlab_on ? 1 : 0
  name_prefix = "${var.prefix}-gitlab-runner-ag-data-science-"
  # This is the ECS optimized image, although we're not running ECS. It's
  # handy since it has everything docker installed, and cuts down on the
  # types of infrastructure
  image_id             = "ami-0749bd3fac17dc2cc"
  instance_type        = var.gitlab_runner_ag_data_science_instance_type
  iam_instance_profile = aws_iam_instance_profile.gitlab_runner_ag_data_science[count.index].name
  security_groups      = ["${aws_security_group.gitlab_runner[count.index].id}"]
  key_name             = aws_key_pair.shared.key_name

  associate_public_ip_address = false

  lifecycle {
    create_before_destroy = true
  }

  root_block_device {
    volume_size = var.gitlab_runner_team_root_volume_size
    encrypted   = true
  }

  user_data = <<EOF
  #!/bin/bash
  #
  set -e
  yum update -y
  yum install -y git jq unzip

  curl "https://s3.eu-west-2.amazonaws.com/mirrors.notebook.uktrade.io/aws-cli/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip awscliv2.zip
  ./aws/install

  curl -L --output /usr/local/bin/gitlab-runner https://s3.eu-west-2.amazonaws.com/mirrors.notebook.uktrade.io/gitlab-runner/gitlab-runner-linux-amd64
  chmod +x /usr/local/bin/gitlab-runner
  ln -s /usr/local/bin/gitlab-runner /usr/bin/gitlab-runner
  useradd --comment 'GitLab Runner' --create-home gitlab-runner --shell /bin/bash
  usermod -aG docker gitlab-runner

  mkdir -p /etc/gitlab-runner
  echo "concurrent = 10" >> /etc/gitlab-runner/config.toml
  echo "check_interval = 1" >> /etc/gitlab-runner/config.toml

  echo "0 0 * * * /usr/bin/docker image prune -f -a --filter until=168h" >> /var/spool/cron/ec2-user

  gitlab-runner install --user=gitlab-runner --working-directory=/home/gitlab-runner
  gitlab-runner start
  # Connects via HTTP, but uses private ip, not public internet
  gitlab-runner register \
    --non-interactive \
    --url "http://${var.gitlab_domain}/" \
    --clone-url "http://${var.gitlab_domain}/" \
    --registration-token "${var.gitlab_runner_ag_data_science_project_token}" \
    --executor "shell" \
    --description "ag data science" \
    --access-level "not_protected" \
    --run-untagged="true" \
    --locked="true"
  EOF
}

resource "aws_iam_instance_profile" "gitlab_runner_ag_data_science" {
  count = var.gitlab_on ? 1 : 0
  name  = "${var.prefix}-gitlab-runner-ag-data-science"
  role  = aws_iam_role.gitlab_runner_ag_data_science[count.index].name
}

resource "aws_iam_role" "gitlab_runner_ag_data_science" {
  count              = var.gitlab_on ? 1 : 0
  name               = "${var.prefix}-gitlab-runner-ag-data-science"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.gitlab_runner_ag_data_science_assume_role[count.index].json
}

data "aws_iam_policy_document" "gitlab_runner_ag_data_science_assume_role" {
  count = var.gitlab_on ? 1 : 0
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "gitlab_runner_ag_data_science" {
  count  = var.gitlab_on ? 1 : 0
  name   = "${var.prefix}-gitlab-runner-ag-data-science"
  policy = data.aws_iam_policy_document.gitlab_runner_ag_data_science[count.index].json
}

data "aws_iam_policy_document" "gitlab_runner_ag_data_science" {
  count = var.gitlab_on ? 1 : 0

  statement {
    actions = [
      "ecr:GetAuthorizationToken",
    ]

    resources = [
      "*"
    ]
  }

  # Read only for the base images
  statement {
    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]

    resources = concat([
      "${aws_ecr_repository.visualisation_base.arn}",
    ], [for i, tool in var.tools : "${aws_ecr_repository.tools[i].arn}"])
  }

  # Allow list and put object for Gitlab private package index
  statement {
    actions = [
      "s3:ListBucket",
    ]
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.notebooks.id}",
    ]
  }

  statement {
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.notebooks.id}/shared/ag_packages/*"
    ]
  }
}
