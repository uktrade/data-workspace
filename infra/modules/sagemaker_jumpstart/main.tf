# README
# these values for environment and model data source were found by deploying a
# JumpStart endpoint with sagemaker studio then copying the values on that model
# using `aws sagemaker describe-model --model-name your_model_name`
# Without these, the endpoint will fail to deploy. You can check cloudwatch logs for the reason
# The standard way to deploy a endpoint is with boto3.sagemaker or python CDK.
# There are no resources online where to find the env and model data source info.
resource "aws_sagemaker_model" "mistral_sagemaker_model" {
  name               = "llm-mistral-7b-instruct-model"
  execution_role_arn = aws_iam_role.sagemaker_trust_role.arn

  primary_container {
    image = var.sagemaker_mistral_public_image
    mode  = "SingleModel"
    environment = {
      SAGEMAKER_MODEL_SERVER_TIMEOUT = "3600"
      ENDPOINT_SERVER_TIMEOUT        = "3600"
      HF_MODEL_ID                    = "/opt/ml/model"
      MAX_BATCH_PREFILL_TOKENS       = "8191"
      MAX_INPUT_LENGTH               = "8191"
      MAX_TOTAL_TOKENS               = "8192"
      MODEL_CACHE_ROOT               = "/opt/ml/model"
      SAGEMAKER_SUBMIT_DIRECTORY     = "/opt/ml/model/code/"
      SAGEMAKER_ENV                  = "1"
      SAGEMAKER_MODEL_SERVER_WORKERS = "1"
      SAGEMAKER_PROGRAM              = "inference.py"
      SM_NUM_GPUS                    = "1"
    }

    model_data_source {
      s3_data_source {
        s3_uri = "s3://jumpstart-cache-prod-us-east-1/huggingface-llm/huggingface-llm-mistral-7b-instruct/artifacts/inference-prepack/v1.0.0/"
        s3_data_type = "S3Prefix"
        compression_type = "None"
      }
    }
  }

  tags = {
    Application = var.app_name
  }
}

resource "aws_sagemaker_endpoint_configuration" "config" {
  name = "chat-bot-sagemaker-config"

  production_variants {
    variant_name           = "mistral-7b-variant"
    model_name             = aws_sagemaker_model.mistral_sagemaker_model.name
    initial_instance_count = 1
    instance_type          = var.sagemaker_inference_compute_size
  }

  tags = {
    Application = var.app_name
  }
}

resource "aws_sagemaker_endpoint" "endpoint" {
  name                 = "sagemaker-mistral-inference-ep"
  endpoint_config_name = aws_sagemaker_endpoint_configuration.config.name

  tags = {
    Application = var.app_name
  }
}

resource "aws_iam_role" "sagemaker_trust_role" {
  name = "sagemaker_role"

  assume_role_policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "sagemaker.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
  EOF

  tags = {
    Application = var.app_name
  }
}

resource "aws_iam_role_policy_attachment" "sagemaker_full_access" {
  role       = aws_iam_role.sagemaker_trust_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}

resource "aws_iam_role_policy_attachment" "s3_read_write_access" {
  role       = aws_iam_role.sagemaker_trust_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# this image was found by deploying a JumpStart endpoint with sagemaker studio
# then copying the value of that model. Without this, python boto3.sagemaker is the next best option.
variable "sagemaker_mistral_public_image" {
  description = "Jumpstart Model mistral public ECR image"
  default     = "763104351884.dkr.ecr.us-east-1.amazonaws.com/huggingface-pytorch-tgi-inference:2.0.1-tgi1.1.0-gpu-py39-cu118-ubuntu20.04"
  type        = string
}

variable "sagemaker_inference_compute_size" {
  description = "EC2 instance size"
  default     = "ml.g5.2xlarge"
  type        = string
}
