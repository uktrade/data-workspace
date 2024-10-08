resource "aws_sagemaker_domain" "sagemaker" {
  domain_name = "SageMaker"
  auth_mode = "IAM"
  vpc_id = aws_vpc.datasets.id
  subnet_ids  = [aws_subnet.datasets.*.id]

  app_network_access_type = aws_vpc.datasets.id
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

data "aws_iam_policy" "sagemaker_full_access_policy" {
  name = "AmazonSageMakerFullAccess"
}

resource "aws_iam_role_policy_attachment" "sagemaker_managed_policy" {
  role = aws_iam_role.sagemaker.name
  policy_arn = data.aws_iam_policy.sagemaker_assume_role.arn
}
