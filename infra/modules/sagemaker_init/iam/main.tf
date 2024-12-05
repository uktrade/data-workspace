# Use the data source to get the bucket ARN from the bucket name
data "aws_s3_bucket" "sagemaker_default_bucket" {
  bucket = var.sagemaker_default_bucket_name
}


# Assume Role Policy for SageMaker Execution Role
data "aws_iam_policy_document" "sagemaker_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]


    principals {
      type        = "Service"
      identifiers = ["sagemaker.amazonaws.com"]
    }
  }
}


# SageMaker Execution Role
resource "aws_iam_role" "sagemaker" {
  name               = "${var.prefix}-sagemaker"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.sagemaker_assume_role.json
}


# Assume Role Policy for SageMaker Inference Role
data "aws_iam_policy_document" "assume_inference_role" {
  statement {
    actions = ["sts:AssumeRole"]


    principals {
      type        = "Service"
      identifiers = ["sagemaker.amazonaws.com"]
    }
  }
}


# SageMaker Inference Role
resource "aws_iam_role" "inference_role" {
  name               = "${var.prefix}-sagemaker-inference-role"
  assume_role_policy = data.aws_iam_policy_document.assume_inference_role.json
}


# Policy Document for SageMaker Permissions
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
      "${var.aws_s3_bucket_notebook.arn}/*"
    ]
  }

  statement {
    actions = [
      "SNS:Subscribe",
      "SNS:SetTopicAttributes",
      "SNS:RemovePermission",
      "SNS:Receive",
      "SNS:Publish",
      "SNS:ListSubscriptionsByTopic",
      "SNS:GetTopicAttributes",
      "SNS:DeleteTopic",
      "SNS:AddPermission",
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "ecr:BatchGetImage",
      "ecr:DescribeImages",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetAuthorizationToken"
    ]
    resources = ["*"]
  }


  statement {
    actions = [
      "cloudwatch:DeleteAlarms",
      "cloudwatch:DescribeAlarms",
      "cloudwatch:GetMetricData",
      "cloudwatch:GetMetricStatistics",
      "cloudwatch:ListMetrics",
      "cloudwatch:PutMetricAlarm",
      "cloudwatch:PutMetricData"
    ]
    resources = ["*"]
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
    resources = ["*",]
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
    resources = ["*",]
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
    resources = ["*",]
  }
}


# Create IAM Policy for SageMaker Permissions
resource "aws_iam_policy" "sagemaker_access_policy" {
  name   = "${var.prefix}-sagemaker-domain"
  policy = data.aws_iam_policy_document.sagemaker_inference_policy_document.json
}


# Attach Policy to SageMaker Role
resource "aws_iam_role_policy_attachment" "sagemaker_managed_policy" {
  role       = aws_iam_role.sagemaker.name
  policy_arn = aws_iam_policy.sagemaker_access_policy.arn
}


# Attach Policy to Inference Role
resource "aws_iam_role_policy_attachment" "sagemaker_inference_role_policy" {
  role       = aws_iam_role.inference_role.name
  policy_arn = aws_iam_policy.sagemaker_access_policy.arn
}
