resource "aws_s3_bucket" "centralized_logs" {
  # Consolidation of logs into S3 Bucket
  bucket        = "${var.prefix}-centralized"
  force_destroy = false

  tags = {
    Name = "${var.prefix} SageMaker Log Bucket"
  }
}



resource "aws_s3_bucket_lifecycle_configuration" "lifecycle" {

  bucket = aws_s3_bucket.centralized_logs.id
  rule {
    status = "Enabled"
    id     = "archive"
    transition {
      days          = var.glacier_transition_days
      storage_class = "GLACIER"
    }

    expiration {
      days = var.retention_days
    }
  }
}

resource "aws_cloudwatch_log_group" "sagemaker_logs" {
  name              = "/aws/sagemaker/centralized_logs"
  retention_in_days = var.log_retention_days
}


resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.centralized_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
