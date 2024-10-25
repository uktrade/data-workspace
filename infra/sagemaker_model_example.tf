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
    instance_type          = "ml.m5.large"
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


# Auto scaling Target for the endpoint of this model
resource "aws_appautoscaling_target" "sagemaker_target" {
  # Max 2 instances at any given time
  max_capacity = 2 
  # Min capacity = 0 ensures our endpoint is off when not needed
  min_capacity = 0
  resource_id = "endpoint/${aws_sagemaker_endpoint.inference_endpoint.name}/variant/aws-spacy-example"
  # Number of desired instance count for the endpoint which can be modified by auto-scaling
  scalable_dimension = "sagemaker:variant:DesiredInstanceCount"
  service_namespace = "sagemaker"
}

# Autoscaling policy based on usage metrics including number of invocation
#  Scale out policy
resource "aws_appautoscaling_policy" "scale_out" {
  name               = "scale-out-policy"
  # Predefined metric for the policy to adjust target value - using invocations
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.sagemaker_target.resource_id
  scalable_dimension = aws_appautoscaling_target.sagemaker_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.sagemaker_target.service_namespace

  #  Config for the target tracking scaling policy
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      #  SageMakerVariantInvocationsPerInstance tracks the average number of invocations per instance
      predefined_metric_type = "SageMakerVariantInvocationsPerInstance"
    }

    # n.b. target_value is a % - inovations will be kept around x% per instance; 
    #  when load exceeds, add more instances - if sig lower scale down.
    #  Cooldowns are in seconds - helps avoid rapid scaling with short-lived spikes.
    target_value       = 70.0
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}

#  Scale in
resource "aws_appautoscaling_policy" "scale_in" {
  name               = "scale-in-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.sagemaker_target.resource_id
  scalable_dimension = aws_appautoscaling_target.sagemaker_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.sagemaker_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      #  Track how many requests are being processed per instance
      predefined_metric_type = "SageMakerVariantInvocationsPerInstance"
    }

  #  Note longer scale in to ensure stablisation so no over-adjusting when demand fluctuates. 
    target_value       = 30.0
    scale_in_cooldown  = 120
    scale_out_cooldown = 60
  }
}