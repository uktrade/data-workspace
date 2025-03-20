resource "aws_s3_bucket" "sagemaker_default_bucket" {
  bucket = "${var.prefix}-eu-west-2-${var.account_id}"
}


resource "aws_s3_bucket_cors_configuration" "sagemaker_default_bucket" {
  bucket                = aws_s3_bucket.sagemaker_default_bucket.id
  expected_bucket_owner = var.account_id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["POST", "PUT", "GET", "HEAD", "DELETE"]
    allowed_origins = ["https://*.sagemaker.aws"]
    expose_headers  = ["ETag", "x-amz-delete-marker", "x-amz-id-2", "x-amz-request-id", "x-amz-server-side-encryption", "x-amz-version-id"]
  }
}


data "aws_iam_policy_document" "sagemaker_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["sagemaker.amazonaws.com"]
    }
  }
}


resource "aws_iam_role" "sagemaker" {
  name               = "${var.prefix}-sagemaker-iam-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.sagemaker_assume_role.json
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


resource "aws_iam_role" "inference_role" {
  name               = "${var.prefix}-sagemaker-iam-inference-role"
  assume_role_policy = data.aws_iam_policy_document.assume_inference_role.json
}


data "aws_iam_policy_document" "sagemaker_inference_policy_document" {
  statement {
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
    ]
    resources = [
      aws_s3_bucket.sagemaker_default_bucket.arn,
      var.aws_s3_bucket_notebook.arn,
      "arn:aws:s3:::jumpstart-cache-prod-eu-west-2",
      "arn:aws:s3:::jumpstart-private-cache-prod-eu-west-2",
    ]
  }
  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = [
      "${aws_s3_bucket.sagemaker_default_bucket.arn}/*",
      "${var.aws_s3_bucket_notebook.arn}/*",
      "arn:aws:s3:::jumpstart-cache-prod-${var.aws_region}/*",
      "arn:aws:s3:::jumpstart-private-cache-prod-${var.aws_region}/*",
    ]
  }
  statement {
    actions = [
      "sns:Publish",
    ]
    resources = ["arn:aws:sns:${var.aws_region}:${var.account_id}:${var.prefix}-async-sagemaker-success-topic",
    "arn:aws:sns:${var.aws_region}:${var.account_id}:${var.prefix}-async-sagemaker-error-topic"]
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
    "cloudwatch:PutMetricData"]
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
    resources = ["*", ]
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
    resources = ["*", ]
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
    resources = ["*", ]
  }
}


resource "aws_iam_policy" "sagemaker_access_policy" {
  name   = "${var.prefix}-sagemaker-iam-access-policy"
  policy = data.aws_iam_policy_document.sagemaker_inference_policy_document.json
}


resource "aws_iam_role_policy_attachment" "sagemaker_managed_policy" {
  role       = aws_iam_role.sagemaker.name
  policy_arn = aws_iam_policy.sagemaker_access_policy.arn
}


resource "aws_iam_role_policy_attachment" "sagemaker_inference_role_policy" {
  role       = aws_iam_role.inference_role.name
  policy_arn = aws_iam_policy.sagemaker_access_policy.arn
}
