resource "aws_sagemaker_model" "example_model" {
  name               = "example-model"
  execution_role_arn = aws_iam_role.inference.arn

  primary_container {
    image = var.sagemaker_example_inference_image
  }

  vpc_config {
    security_group_ids = ["${aws_security_group.notebooks.id}"]
    subnets = aws_subnet.private_without_egress.*.id
  }
}

resource "aws_iam_role" "inference" {
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
  role = aws_iam_role.inference.name
  policy_arn = data.aws_iam_policy.sagemaker_ro_access_policy.arn
}

data "aws_iam_policy" "sagemaker_ro_access_policy" {
  name = "AmazonSageMakerFullAccess"
}

resource "aws_sagemaker_endpoint" "inference_endpoint" {
  name = "inference-endpoint"
  endpoint_config_name = aws_sagemaker_endpoint_configuration.sagemaker_endpoint_configuration.name
}

resource "aws_sagemaker_endpoint_configuration" "sagemaker_endpoint_configuration" {
  name = "sagemaker-endpoint-config"

  production_variants {
    variant_name           = "aws-spacy-example"
    model_name             = aws_sagemaker_model.example_model.name
    instance_type          = "ml.t2.medium"
    initial_instance_count = 1
  }
  # Async config
  async_inference_config {
    client_config {
        max_concurrent_invocations_per_instance = 1
    }
    output_config {
        s3_output_path = "https://${data.aws_s3_bucket.sagemaker_default_bucket.bucket_regional_domain_name}"
    }
 }
}

data "aws_s3_bucket" "sagemaker_default_bucket" {
  bucket = "sagemaker-eu-west-2-339713044404"
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
