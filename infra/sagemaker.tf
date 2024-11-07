resource "aws_sagemaker_domain" "sagemaker" {
  domain_name = "SageMaker"
  auth_mode = "IAM"
  vpc_id = aws_vpc.notebooks.id
  subnet_ids  = aws_subnet.private_without_egress.*.id
  app_network_access_type = "VpcOnly"

  default_user_settings {
    execution_role = aws_iam_role.sagemaker.arn
  }
}

resource "aws_iam_role" "sagemaker" {
  name = "sagemaker"
  path = "/"
  assume_role_policy = data.aws_iam_policy_document.sagemaker_assume_role.json
}

data "aws_iam_policy_document" "sagemaker_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = ["sagemaker.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "sagemaker_access_policy" {
  name   = "${var.prefix}-sagemaker-domain"
  policy = data.aws_iam_policy_document.sagemaker_inference_policy_document.json
}

resource "aws_iam_role_policy_attachment" "sagemaker_managed_policy" {
  role = aws_iam_role.sagemaker.name
  policy_arn = aws_iam_policy.sagemaker_access_policy.arn
}

resource "aws_security_group" "notebooks_endpoints" {
  name        = "${var.prefix}-notebooks-endpoints"
  description = "${var.prefix}-notebooks-endpoints"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.prefix}-notebooks-endpoints"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "notebooks_endpoint_ingress_sagemaker" {
  description = "endpoint-ingress-from-datasets-vpc"

  security_group_id        = aws_security_group.notebooks_endpoints.id
  cidr_blocks         = [aws_vpc.notebooks.cidr_block]

  type      = "ingress"
  from_port = "0"
  to_port   = "65535"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "notebooks_endpoint_egress_sagemaker" {
  description = "endpoint-ingress-from-datasets-vpc"

  security_group_id        = aws_security_group.notebooks_endpoints.id
  cidr_blocks         = [aws_vpc.notebooks.cidr_block]

  type      = "egress"
  from_port = "0"
  to_port   = "65535"
  protocol  = "tcp"
}

data "aws_s3_bucket" "sagemaker_default_bucket" {
  bucket = "${var.sagemaker_default_bucket}"
}

resource "aws_iam_role" "inference_role" {
  assume_role_policy = data.aws_iam_policy_document.assume_inference_role.json
}

data "aws_iam_policy_document" "assume_inference_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["sagemaker.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "sagemaker_inference_role_policy" {
  role = aws_iam_role.inference_role.name
  policy_arn = aws_iam_policy.sagemaker_ro_access_policy.arn
}

resource "aws_iam_policy" "sagemaker_ro_access_policy" {
  name   = "${var.prefix}-sagemaker-execution"
  policy = data.aws_iam_policy_document.sagemaker_inference_policy_document.json
}

data "aws_iam_policy_document" "sagemaker_inference_policy_document" {

  statement {
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]

    resources = [
      "arn:aws:s3:::*sagemaker*",
      "${aws_s3_bucket.notebooks.arn}/*"
    ]
  }

  statement {
    actions = [
      "ecr:BatchGetImage",
      "ecr:DescribeImages",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchCheckLayerAvailability"
    ]

    resources = [
      # "${aws_ecr_repository.sagemaker.arn}",
      "*"
    ]
  }

  statement {
    actions = [
      "cloudwatch:DeleteAlarms",
      "cloudwatch:DescribeAlarms",
      "cloudwatch:GetMetricData",
      "cloudwatch:GetMetricStatistics",
      "cloudwatch:ListMetrics",
      "cloudwatch:PutMetricAlarm",
      "cloudwatch:PutMetricData",
    ]

    resources = [
      "*",
    ]
  }

  statement {
    actions = [
      "application-autoscaling:DeleteScalingPolicy",
      "application-autoscaling:DeleteScheduledAction",
      "application-autoscaling:DeregisterScalableTarget",
      "application-autoscaling:DescribeScalableTargets",
      "application-autoscaling:DescribeScalingActivities",
      "application-autoscaling:DescribeScalingPolicies",
      "application-autoscaling:DescribeScheduledActions",
      "application-autoscaling:PutScalingPolicy",
      "application-autoscaling:PutScheduledAction",
      "application-autoscaling:RegisterScalableTarget",
    ]

    resources = [
      "*",
    ]
  }

  statement {
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:CreateNetworkInterfacePermission",
      "ec2:CreateVpcEndpoint",
      "ec2:DeleteNetworkInterface",
      "ec2:DeleteNetworkInterfacePermission",
      "ec2:DescribeDhcpOptions",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeRouteTables",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeVpcEndpoints",
      "ec2:DescribeVpcs",
    ]

    resources = [
      "*",
    ]
  }

  statement {
    actions = [
      "logs:CreateLogDelivery",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DeleteLogDelivery",
      "logs:Describe*",
      "logs:GetLogDelivery",
      "logs:GetLogEvents",
      "logs:ListLogDeliveries",
      "logs:PutLogEvents",
      "logs:PutResourcePolicy",
      "logs:UpdateLogDelivery",
    ]

    resources = [
      "*",
    ]
  }
}

#  Legacy code below for scheduling autoscaling
# # Scale out schedule during weekday mornings (8 AM, Monday to Friday)
# resource "aws_appautoscaling_scheduled_action" "scale_out_weekdays" {
#   name                  = "scale-out-during-weekdays"
#   service_namespace     = "sagemaker"
#   schedule              = "cron(0 8 ? * MON-FRI *)"  # Every weekday at 8 AM
#   resource_id           = "endpoint/${aws_sagemaker_endpoint.inference_endpoint.name}/variant/aws-spacy-example"
#   scalable_dimension    = "sagemaker:variant:DesiredInstanceCount"

#   scalable_target_action {
#     min_capacity = 1
#     max_capacity = 2
#   }
# }

# # Scale in schedule during off-peak hours (6 PM, Monday to Friday)
# resource "aws_appautoscaling_scheduled_action" "scale_in_weekdays" {
#   name                  = "scale-in-during-weekdays"
#   service_namespace     = "sagemaker"
#   schedule              = "cron(0 18 ? * MON-FRI *)"  # Every weekday at 6 PM
#   resource_id           = "endpoint/${aws_sagemaker_endpoint.inference_endpoint.name}/variant/aws-spacy-example"
#   scalable_dimension    = "sagemaker:variant:DesiredInstanceCount"

#   scalable_target_action {
#     min_capacity = 0
#     max_capacity = 0
#   }
# }

# # Scale in schedule for weekends (scale down to zero on Saturdays and Sundays)
# resource "aws_appautoscaling_scheduled_action" "scale_in_weekends" {
#   name                  = "scale-in-during-weekends"
#   service_namespace     = "sagemaker"
#   schedule              = "cron(0 0 ? * SAT,SUN *)"  # Every Saturday and Sunday at midnight
#   resource_id           = "endpoint/${aws_sagemaker_endpoint.inference_endpoint.name}/variant/aws-spacy-example"
#   scalable_dimension    = "sagemaker:variant:DesiredInstanceCount"

#   scalable_target_action {
#     min_capacity = 0
#     max_capacity = 0
#   }
# }
