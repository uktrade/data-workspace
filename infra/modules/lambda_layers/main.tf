// Useful guide on creating lambda layers using an ec2 instance:
// https://aws.amazon.com/blogs/database/run-event-driven-stored-procedures-with-aws-lambda-for-amazon-aurora-postgresql-and-amazon-rds-for-postgresql/
// NOTE: possibly can be done also locally with a Docker container of the Amazon Linux? But not tested


resource "aws_s3_bucket" "lambda_layers" {
  bucket = "${var.prefix}-${var.aws_region}-lambda-layers"
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}


resource "aws_lambda_layer_version" "boto3_stubs_s3" {
  layer_name  = "boto3-stubs-s3"
  s3_bucket   = aws_s3_bucket.lambda_layers.id
  s3_key      = "boto3-stubs-s3-layer.zip"
  description = "Contains boto3-stubs[s3]"
}
