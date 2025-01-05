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
      "s3:DeleteObject",
      "s3:GetBucketLocation",
    ]
    resources = [
      "arn:aws:s3:::*sagemaker*",
      "${var.aws_s3_bucket_notebook.arn}/*",
      "arn:aws:s3:::*",  # TODO: reduce to jumpstart-cache-prod-eu-west-2, jumpstart-private-cache-prod-eu-west-2
    ]
  }

  statement {
    actions = [
      "sns:Publish",
    ]
    resources = ["arn:aws:sns:eu-west-2:${var.account_id}:async-sagemaker-success-topic"]
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


# Lambdas
data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}


data "aws_iam_policy_document" "lambda_execution_policy" {
  statement {
    actions = [
      "s3:PutObject",
      "s3:GetBucketLocation",
      "s3:ListBucket"
    ]
    resources = [
      "${var.s3_bucket_arn}/*",
      "${var.s3_bucket_arn}"
    ]
  }

  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:eu-west-2:${var.account_id}:log-group:*"
    ]
  }
}

data "aws_iam_policy_document" "cloudwatch_log_invoke_policy" {
  statement {
    actions = [
      "lambda:InvokeFunction"
    ]
    resources = [
      var.lambda_function_arn
    ]
  }
}

resource "aws_iam_policy" "lambda_execution_policy" {
  name   = "${var.prefix}-lambda-execution-policy"
  policy = data.aws_iam_policy_document.lambda_execution_policy.json
}

resource "aws_iam_policy" "cloudwatch_log_invoke_policy" {
  name   = "${var.prefix}-cloudwatch-log-invoke-policy"
  policy = data.aws_iam_policy_document.cloudwatch_log_invoke_policy.json
}

resource "aws_iam_role" "lambda_execution_role" {
  name               = "${var.prefix}-lambda-execution-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "attach_lambda_execution_policy" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_execution_policy.arn
}

resource "aws_iam_role_policy_attachment" "attach_cloudwatch_log_invoke_policy" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.cloudwatch_log_invoke_policy.arn
}
