resource "aws_codebuild_project" "tools" {
  count        = length(var.tools)
  name         = "${var.prefix}-${var.tools[count.index].name}"
  description  = "${var.prefix}-${var.tools[count.index].name}"
  service_role = aws_iam_role.tools_codebuild[count.index].arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  source {
    type            = "GITHUB"
    location        = var.tools_github_source_url
    git_clone_depth = 1

    # Although not seemingly common, it's quite handy for the buildspec to be in the Terraform, so
    # it has access to all of Terraform's resources and variables. It also allows quite fast
    # iteration, because it can be quickly deployed with a `terraform apply`
    buildspec = <<-EOT
      version: 0.2

      phases:
        build:
          commands:
            - aws ecr get-login-password --region eu-west-2 | docker login --username AWS --password-stdin ${aws_ecr_repository.tools[count.index].repository_url}
            - docker buildx create --use --name builder --driver docker-container
            - |
              docker buildx build --builder builder \
                --file Dockerfile \
                --build-arg GIT_COMMIT=$${CODEBUILD_SOURCE_VERSION} \
                --push -t ${aws_ecr_repository.tools[count.index].repository_url}:master \
                --cache-from type=registry,ref=${aws_ecr_repository.tools[count.index].repository_url}:cache \
                --cache-to mode=max,image-manifest=true,oci-mediatypes=true,type=registry,ref=${aws_ecr_repository.tools[count.index].repository_url}:cache \
                --target ${var.tools[count.index].docker_target} \
                .
    EOT
  }
  source_version = "main"

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true # For running the Docker daemon
  }

  logs_config {
    cloudwatch_logs {
      group_name  = aws_cloudwatch_log_group.tools_codebuild[count.index].name
      stream_name = "main"
    }
  }

  # This isn't strictly needed, but it means that requests from CodeBuild will come via our
  # NAT instance, and so from our IP, and so less likely to hit rate limits that are based on IP
  # addresses that are shared with other CodeBuild users. Specifically, pulling from Docker Hub
  vpc_config {
    vpc_id             = aws_vpc.main.id
    subnets            = aws_subnet.private_with_egress[*].id
    security_group_ids = [aws_security_group.tools_codebuild[count.index].id]
  }
}

resource "aws_iam_role" "tools_codebuild" {
  count = length(var.tools)
  name  = "${var.prefix}-${var.tools[count.index].name}-codebuild"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "tools_codebuild" {
  count = length(var.tools)
  name  = "${var.prefix}-${var.tools[count.index].name}-codebuild"
  role  = aws_iam_role.tools_codebuild[count.index].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat([
      {
        Effect = "Allow",
        Resource = [
          "${aws_cloudwatch_log_group.tools_codebuild[count.index].arn}",
          "${aws_cloudwatch_log_group.tools_codebuild[count.index].arn}:*",
        ],
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ],
      },
      {
        Effect = "Allow",
        Resource = [
          "*",
        ],
        Action = [
          "ecr:GetAuthorizationToken",
        ],
      },
      {
        Effect = "Allow",
        Resource = [
          aws_ecr_repository.tools[count.index].arn,
        ],
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart",
          "ecr:GetDownloadUrlForLayer",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage",
        ],
      },
      # Codebuild requires various VPC permissions to run things in our VPC
      # (which is maybe inconsistent with ECS, which doesn't need similar permissions)
      # https://docs.aws.amazon.com/codebuild/latest/userguide/auth-and-access-control-iam-identity-based-access-control.html#customer-managed-policies-example-create-vpc-network-interface
      {
        Effect = "Allow",
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeDhcpOptions",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeVpcs"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "ec2:CreateNetworkInterfacePermission"
        ],
        Resource = "arn:aws:ec2:${data.aws_region.aws_region.name}:${data.aws_caller_identity.aws_caller_identity.account_id}:network-interface/*",
        Condition = {
          StringEquals = {
            "ec2:AuthorizedService" = "codebuild.amazonaws.com"
          },
          ArnEquals = {
            "ec2:Subnet" = aws_subnet.private_with_egress[*].arn
          }
        }
      }
      ], var.codeconnection_arn != "" ? [
      {
        Effect = "Allow",
        Action = [
          "codeconnections:GetConnectionToken",
        ],
        Resource = var.codeconnection_arn,
      }
    ] : [])
  })
}


resource "aws_cloudwatch_log_group" "tools_codebuild" {
  count             = length(var.tools)
  name              = "${var.prefix}-${var.tools[count.index].name}-codebuild"
  retention_in_days = "3653"
}

resource "aws_security_group" "tools_codebuild" {
  count       = length(var.tools)
  name        = "${var.prefix}-${var.tools[count.index].name}-codebuild"
  description = "${var.prefix}-${var.tools[count.index].name}-codebuild"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.prefix}-${var.tools[count.index].name}-codebuild"
  }
}

# Allows the Docker build to pull in packages from the outside world, e.g. PyPI
resource "aws_vpc_security_group_egress_rule" "tools_codebuild_https_to_all" {
  count             = length(var.tools)
  security_group_id = aws_security_group.tools_codebuild[count.index].id
  cidr_ipv4         = "0.0.0.0/0"

  ip_protocol = "tcp"
  from_port   = "443"
  to_port     = "443"
}

# Allows install of Debian packages which are via HTTP
resource "aws_vpc_security_group_egress_rule" "tools_codebuild_http_to_all" {
  count             = length(var.tools)
  security_group_id = aws_security_group.tools_codebuild[count.index].id
  cidr_ipv4         = "0.0.0.0/0"

  ip_protocol = "tcp"
  from_port   = "80"
  to_port     = "80"
}
