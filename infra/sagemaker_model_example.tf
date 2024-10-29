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
  # Min capacity = 1 ensures our endpoint is at a minimum when not needed but ready to go
  min_capacity = 1
  resource_id = "endpoint/${aws_sagemaker_endpoint.inference_endpoint.name}/variant/aws-spacy-example"
  # Number of desired instance count for the endpoint which can be modified by auto-scaling
  scalable_dimension = "sagemaker:variant:DesiredInstanceCount"
  service_namespace = "sagemaker"
}

# Autoscaling policy based on usage metrics around CPU % n.b. this may need altering 
#  if using a GPU on the Scale out policy
resource "aws_appautoscaling_policy" "scale_out_cpu" {
  name               = "scale-out-policy-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.sagemaker_target.resource_id
  scalable_dimension = aws_appautoscaling_target.sagemaker_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.sagemaker_target.service_namespace

  # Config for the target tracking scaling policy
  target_tracking_scaling_policy_configuration {
    customized_metric_specification {
      metric_name = "CPUUtilization"
      namespace   = "AWS/SageMaker"  
      statistic   = "Average"
      unit        = "Percent"
    }

    target_value       = 70.0  # Scale out if CPU utilization exceeds 70%
    scale_in_cooldown  = 60    # Cooldown to prevent frequent scaling in
    scale_out_cooldown = 60    # Cooldown to prevent frequent scaling out
  }
}


#  Scale in - using cloudwatch alarm to ensure we have distinct thresholds
#  Alongside a step scaling policy
#  Now altered for low CPU utilisation as metric for inovcations not present 
resource "aws_cloudwatch_metric_alarm" "scale_in_alarm" {
  alarm_name          = "sm-low-cpu-util"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 3 # Increased eval periods to filter short-lived spikes (health check related)
  metric_name         = "CPUUtilization"
  namespace           = "/aws/sagemaker/Endpoints"
  period              = 60
  statistic           = "Average"
  threshold           = 5.0  # Trigger scale-in if utilization drops below 5%
  

  dimensions = {
    EndpointName = aws_sagemaker_endpoint.inference_endpoint.name
    VariantName = "aws-spacy-example"
  }

  alarm_description = "Alarm if SageMaker CPU util rate  <5%. Triggers scale in due to being idle."
  alarm_actions     = [aws_appautoscaling_policy.scale_in_to_zero.arn]
  # treat_missing_data = "breaching"  # Treat missing data as breaching to force evaluation
}

# Alternative: Memory Utilization
resource "aws_cloudwatch_metric_alarm" "scale_in_memory_alarm" {
  alarm_name          = "sm-low-memory-util"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 3
  metric_name         = "MemoryUtilization"
  namespace           = "/aws/sagemaker/Endpoints"
  period              = 60
  statistic           = "Average"
  threshold           = 4.0  # Trigger scale-in if memory utilization drops below 4%
  

  dimensions = {
    EndpointName = aws_sagemaker_endpoint.inference_endpoint.name
    VariantName = "aws-spacy-example"
  }

  alarm_description = "SageMaker endpoint alarm if memory utilization < 4%"
  alarm_actions     = [aws_appautoscaling_policy.scale_in_to_zero.arn]
  # treat_missing_data = "breaching"  # Treat missing data as breaching to force evaluation
}

# Step Scaling Policy for Scaling In to Zero which the cloudwatch alarms utilise
resource "aws_appautoscaling_policy" "scale_in_to_zero" {
  name               = "scale-in-to-zero-policy"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.sagemaker_target.resource_id
  scalable_dimension = aws_appautoscaling_target.sagemaker_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.sagemaker_target.service_namespace

  step_scaling_policy_configuration {
    adjustment_type = "ExactCapacity"

    # Adjust capacity to 1 when underutilization is detected
    step_adjustment {
      metric_interval_upper_bound = 1
      scaling_adjustment          = 1  # Set capacity to 1 instances
    }

    cooldown = 120  # Longer cooldown to prevent frequent scale-in actions
  }
}
