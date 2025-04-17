resource "aws_codebuild_project" "admin" {
  name         = "${var.prefix}-admin"
  description  = "${var.prefix}-admin"
  service_role = aws_iam_role.admin_codebuild.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  source {
    type            = "GITHUB"
    location        = var.admin_github_source_url
    git_clone_depth = 1

    # Although not seemingly common, it's quite handy for the buildspec to be in the Terraform, so
    # it has access to all of Terraform's resources and variables. It also allows quite fast
    # iteration, because it can be quickly deployed with a `terraform apply`
    buildspec = <<-EOT
      version: 0.2

      phases:
        build:
          commands:
            - aws ecr get-login-password --region eu-west-2 | docker login --username AWS --password-stdin ${aws_ecr_repository.admin.repository_url}
            - docker buildx create --use --name builder --driver docker-container
            - |
              docker buildx build --builder builder \
                --file Dockerfile \
                --build-arg GIT_COMMIT=$${CODEBUILD_SOURCE_VERSION} \
                --push -t ${aws_ecr_repository.admin.repository_url}:master \
                --cache-from type=registry,ref=${aws_ecr_repository.admin.repository_url}:cache \
                --cache-to mode=max,image-manifest=true,oci-mediatypes=true,type=registry,ref=${aws_ecr_repository.admin.repository_url}:cache \
                .
            - aws ecs update-service --cluster ${aws_ecs_cluster.main_cluster.name} --service ${aws_ecs_service.admin.name} --force-new-deployment
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
      group_name  = aws_cloudwatch_log_group.admin_codebuild.name
      stream_name = "main"
    }
  }

  # This isn't strictly needed, but it means that requests from CodeBuild will come via our
  # NAT instance, and so from our IP, and so less likely to hit rate limits that are based on IP
  # addresses that are shared with other CodeBuild users. Specifically, pulling from Docker Hub
  vpc_config {
    vpc_id             = aws_vpc.main.id
    subnets            = aws_subnet.private_with_egress[*].id
    security_group_ids = [aws_security_group.admin_codebuild.id]
  }
}

resource "aws_codebuild_webhook" "admin_release" {
  count        = var.admin_codebuild_release_on ? 1 : 0
  project_name = aws_codebuild_project.admin.name
  build_type   = "BUILD"

  filter_group {
    filter {
      type    = "EVENT"
      pattern = "RELEASED"
    }
  }
}

resource "aws_iam_role" "admin_codebuild" {
  name = "${var.prefix}-admin-codebuild"

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

resource "aws_iam_role_policy" "admin_codebuild" {
  name = "${var.prefix}-admin-codebuild"
  role = aws_iam_role.admin_codebuild.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat([
      {
        Effect = "Allow",
        Resource = [
          "${aws_cloudwatch_log_group.admin_codebuild.arn}",
          "${aws_cloudwatch_log_group.admin_codebuild.arn}:*",
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
          aws_ecr_repository.admin.arn,
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
      {
        Effect = "Allow",
        Resource = [
          aws_ecs_service.admin.id,
        ],
        Action = [
          "ecs:UpdateService",
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

resource "aws_cloudwatch_log_group" "admin_codebuild" {
  name              = "${var.prefix}-admin-codebuild"
  retention_in_days = "3653"
}

resource "aws_security_group" "admin_codebuild" {
  name        = "${var.prefix}-admin-codebuild"
  description = "${var.prefix}-admin-codebuild"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.prefix}-admin-codebuild"
  }
}

module "admin_codebuild_outgoing_http_to_all" {
  source = "./modules/security_group_client_server_connections"

  client_security_groups = [aws_security_group.admin_codebuild]
  # Allows install of Debian packages which are via HTTP
  server_ipv4_cidrs = [
    "0.0.0.0/0"
  ]
  ports = [80]
}

module "admin_codebuild_outgoing_https_vpc_endpoints" {
  source = "./modules/security_group_client_server_connections"

  client_security_groups = [aws_security_group.admin_codebuild]
  server_security_groups = concat([
    aws_security_group.ecr_api,
    aws_security_group.ecr_dkr,
    aws_security_group.ecs,
    aws_security_group.cloudwatch,
    ]
  )
  server_prefix_list_ids = [
    aws_vpc_endpoint.s3.prefix_list_id
  ]
  # Allows the Docker build to pull in packages from the outside world, e.g. PyPI
  server_ipv4_cidrs = [
    "0.0.0.0/0"
  ]
  ports = [443]
}
