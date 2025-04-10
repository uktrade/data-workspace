resource "aws_s3_bucket" "tests" {
  bucket = "${var.prefix}-test-resources"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}
