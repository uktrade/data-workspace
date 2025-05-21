resource "aws_ecr_repository" "gitlab" {
  name = "${var.prefix}-gitlab"
}

resource "aws_ecr_lifecycle_policy" "gitlab" {
  repository = aws_ecr_repository.gitlab.name
  policy     = data.aws_ecr_lifecycle_policy_document.gitlab.json
}

data "aws_ecr_lifecycle_policy_document" "gitlab" {
  rule {
    priority = 1
    selection {
      tag_status       = "tagged"
      tag_pattern_list = ["*"]
      count_type       = "imageCountMoreThan"
      count_number     = 1
    }
  }
  rule {
    priority = 2
    selection {
      tag_status   = "untagged"
      count_type   = "sinceImagePushed"
      count_unit   = "days"
      count_number = 1
    }
  }
}
