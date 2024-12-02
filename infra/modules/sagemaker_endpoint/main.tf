# SageMaker Endpoint Configuration
resource "aws_sagemaker_endpoint_configuration" "endpoint_config" {
  name = var.endpoint_config_name

  production_variants {
    variant_name           = var.variant_name
    model_name             = var.model_name
    instance_type          = var.instance_type
    initial_instance_count = var.initial_instance_count
    container_startup_health_check_timeout_in_seconds = var.container_startup_health_check_timeout_in_seconds
  }

  # Async config for the SageMaker endpoint
  async_inference_config {
    client_config {
      max_concurrent_invocations_per_instance = 1
    }
    output_config {
      s3_output_path = var.async_output_s3_path
      notification_config {
        #include_inference_response_in = ["SUCCESS_NOTIFICATION_TOPIC", "ERROR_NOTIFICATION_TOPIC"]
        success_topic = aws_sns_topic.async-sagemaker-success-topic.arn
        error_topic = aws_sns_topic.async-sagemaker-error-topic.arn
      }
    }
  }
}

resource "aws_sns_topic" "async-sagemaker-success-topic" {
  name = "async-sagemaker-success-topic"
}

resource "aws_sns_topic" "async-sagemaker-error-topic" {
  name = "async-sagemaker-error-topic"
}


# SageMaker Endpoint
resource "aws_sagemaker_endpoint" "sagemaker_endpoint" {
  name                = var.endpoint_name
  endpoint_config_name = aws_sagemaker_endpoint_configuration.endpoint_config.name

  depends_on = [aws_sagemaker_endpoint_configuration.endpoint_config, aws_sns_topic.async-sagemaker-error-topic, aws_sns_topic.async-sagemaker-success-topic]
}
