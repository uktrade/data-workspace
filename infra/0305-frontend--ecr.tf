resource "aws_ecr_repository" "admin" {
  name = "${var.prefix}-admin"
}

resource "aws_ecr_lifecycle_policy" "admin_keep_last_five_releases" {
  repository = aws_ecr_repository.admin.name
  policy     = data.aws_ecr_lifecycle_policy_document.keep_last_five_releases.json
}

data "aws_ecr_lifecycle_policy_document" "keep_last_five_releases" {
  # always keep five images that fit semantic versioning pattern
  rule {
    priority = 1
    selection {
      tag_status       = "tagged"
      tag_pattern_list = ["v*.*.*"]
      count_type       = "imageCountMoreThan"
      count_number     = 5
    }
  }
  # keep five other images (from PR merge builds etc)
  rule {
    priority = 2
    selection {
      tag_status       = "tagged"
      tag_pattern_list = ["*"]
      count_type       = "imageCountMoreThan"
      count_number     = 5
    }
  }
  # ... and just in case we somehow end up with untagged images, expire them after 1 day
  rule {
    priority = 3
    selection {
      tag_status   = "untagged"
      count_type   = "sinceImagePushed"
      count_unit   = "days"
      count_number = 1
    }
  }
}
