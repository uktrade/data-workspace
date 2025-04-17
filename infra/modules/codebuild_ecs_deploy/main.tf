###################################################################################################
#
# A module to avoid the boilerplate of making a CodeBuild project that builds a Docker image from
# a Dockerfile in a GitHub repository, pushes the image to ECS, and deploys an ECS service
#
# The exception to the boilerplate is the security group and security group rules - these must
# be constructed _outside_ of this module. This is so
#
# - The module is flexible - what security group rules need to exist depends on what VPC this runs
#   in and what the Dockerfile build needs to connect to
# - Security group rules are not hidden away inside a module, but remain at the top level. This
#   aids in reviewing them
#
# See https://developer.hashicorp.com/terraform/language/modules/develop/composition#dependency-inversion
# for similar arguments for what is known as dependency injection / inversion
#
# Typically the security groups need rules constructed to communicate with:
#
# - Both API and Docker ECR endpoints
# - ECS API Endpoint
# - CloudWatch (logs) endpoints
# - Anything the Docker build needs to connect to (which might have to be 0.0.0.0/0)
#
###################################################################################################


#################
# Input variables

variable "name" {
  description = "The name of the CodeBuild project and (prefix of) the CloudWatch log group to create"
  type        = string
}

variable "github_source_url" {
  description = "The HTTPS URL of the source repository"
  type        = string
}

variable "default_source_branch" {
  description = "The source branch to build (if not a release)"
  type        = string
  default     = "main"
}

variable "dockerfile_path" {
  description = "The path to the Dockerfile in the source repository"
  type        = string
  default     = "Dockerfile"
}

variable "ecs_service" {
  description = "The ECS service to deploy"
  type = object({
    name    = string
    id      = string
    cluster = string
  })
}

variable "ecr_repository" {
  description = "The ECR repository to push to"
  type = object({
    repository_url = string
    arn            = string
  })
}

variable "default_ecr_tag" {
  description = "The ECR tag to build to (if not a release)"
  type        = string
  default     = "master"
}

variable "ecr_cache_tag" {
  description = "The ECR tag to use as a cache"
  type        = string
  default     = "cache"
}

variable "security_group" {
  description = "The security group the CodeBuild job will run under. Security group rules would typically"
  type = object({
    id     = string
    vpc_id = string
  })
}

variable "subnets" {
  description = "The subnets the CodeBuild job will rub under"
  type = list(object({
    id  = string
    arn = string
  }))
}

variable "build_on_release" {
  description = "Whether to run the project automatically on GitHub release"
  type        = bool
  default     = false
}

variable "codeconnection_arn" {
  description = "The ARN of the CodeConnection used to fetch from GitHub, and (if build_on_release is true) setup a webhook"
  type        = string
  default     = ""
}

variable "region_name" {
  description = "The region name of of the ECR repository and subnets - needed for technical/security reasons"
  type        = string
}

variable "account_id" {
  description = "The account ID of subnets - needed for technical/security reasons"
  type        = string
}


##########################################
# CodeBuild project and required resources

resource "aws_codebuild_project" "main" {
  name         = var.name
  service_role = aws_iam_role.main.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  source {
    type            = "GITHUB"
    location        = var.github_source_url
    git_clone_depth = 1

    # Although not seemingly common, it's quite handy for the buildspec to be in the Terraform, so
    # it has access to all of Terraform's resources and variables. It also allows quite fast
    # iteration, because it can be quickly deployed with a `terraform apply`
    buildspec = <<-EOT
      version: 0.2

      phases:
        build:
          commands:
            - aws ecr get-login-password --region ${var.region_name} | docker login --username AWS --password-stdin ${var.ecr_repository.repository_url}
            - docker buildx create --use --name builder --driver docker-container
            - |
              docker buildx build --builder builder \
                --file Dockerfile \
                --build-arg GIT_COMMIT=$${CODEBUILD_SOURCE_VERSION} \
                --push -t ${var.ecr_repository.repository_url}:master \
                --cache-from type=registry,ref=${var.ecr_repository.repository_url}:${var.ecr_cache_tag} \
                --cache-to mode=max,image-manifest=true,oci-mediatypes=true,type=registry,ref=${var.ecr_repository.repository_url}:${var.ecr_cache_tag}  \
                .
            - aws ecs update-service --cluster ${var.ecs_service.cluster} --service ${var.ecs_service.name} --force-new-deployment
    EOT
  }
  source_version = var.default_source_branch

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true # For running the Docker daemon
  }

  logs_config {
    cloudwatch_logs {
      group_name  = aws_cloudwatch_log_group.main.name
      stream_name = "main"
    }
  }

  # This isn't strictly needed, but it means that requests from CodeBuild will come via our
  # NAT instance, and so from our IP, and so less likely to hit rate limits that are based on IP
  # addresses that are shared with other CodeBuild users. Specifically, pulling from Docker Hub
  vpc_config {
    vpc_id             = var.security_group.vpc_id
    subnets            = var.subnets[*].id
    security_group_ids = [var.security_group.id]
  }
}

resource "aws_codebuild_webhook" "main" {
  count        = var.build_on_release && var.codeconnection_arn != "" ? 1 : 0
  project_name = aws_codebuild_project.main.name
  build_type   = "BUILD"

  filter_group {
    filter {
      type    = "EVENT"
      pattern = "RELEASED"
    }
  }
}

resource "aws_iam_role" "main" {
  name = var.name

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

resource "aws_iam_role_policy" "main" {
  name = var.name
  role = aws_iam_role.main.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat([
      {
        Effect = "Allow",
        Resource = [
          "${aws_cloudwatch_log_group.main.arn}",
          "${aws_cloudwatch_log_group.main.arn}:*",
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
          var.ecr_repository.arn,
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
          var.ecs_service.id,
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
        Resource = "arn:aws:ec2:${var.region_name}:${var.account_id}:network-interface/*",
        Condition = {
          StringEquals = {
            "ec2:AuthorizedService" = "codebuild.amazonaws.com"
          },
          ArnEquals = {
            "ec2:Subnet" = var.subnets[*].arn
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

resource "aws_cloudwatch_log_group" "main" {
  name              = "${var.name}-codebuild"
  retention_in_days = "3653"
}
