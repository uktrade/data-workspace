resource "aws_sagemaker_model" "example_model" {
  name               = "example-model"
  execution_role_arn = aws_iam_role.inference.arn

  primary_container {
    image = var.sagemaker_example_inference_image
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

    # Serverless Inference Config
    serverless_config {
        max_concurrency    = 3
        memory_size_in_mb  = 1024
    }

  }
}
