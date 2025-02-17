resource "aws_sns_topic" "scale_up_from_0_to_1" {

  name = "${aws_sagemaker_endpoint.main.name}-scale-up-from-0-to-1"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        },
        Action   = "sns:Publish",
        Resource = "*"
      }
    ]
  })
}


resource "aws_sns_topic" "scale_down_from_n_to_0" {

  name = "${aws_sagemaker_endpoint.main.name}-scale-down-from-n-to-0"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        },
        Action   = "sns:Publish",
        Resource = "*"
      }
    ]
  })
}


resource "aws_sns_topic" "scale_down_from_n_to_nm1" {

  name = "${aws_sagemaker_endpoint.main.name}-scale-down-from-n-to-nm1"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        },
        Action   = "sns:Publish",
        Resource = "*"
      }
    ]
  })
}


resource "aws_sns_topic" "scale_up_from_n_to_np1" {

  name = "${aws_sagemaker_endpoint.main.name}-scale-up-from-n-to-np1"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        },
        Action   = "sns:Publish",
        Resource = "*"
      }
    ]
  })
}



