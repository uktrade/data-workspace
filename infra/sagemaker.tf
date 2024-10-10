resource "aws_sagemaker_domain" "sagemaker" {
  domain_name = "SageMaker"
  auth_mode = "IAM"
  vpc_id = aws_vpc.main.id
  subnet_ids  = aws_subnet.private_with_egress.*.id
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

data "aws_iam_policy" "sagemaker_access_policy" {
  name = "AmazonSageMakerReadOnly"
}

resource "aws_iam_role_policy_attachment" "sagemaker_managed_policy" {
  role = aws_iam_role.sagemaker.name
  policy_arn = data.aws_iam_policy.sagemaker_access_policy.arn
}
