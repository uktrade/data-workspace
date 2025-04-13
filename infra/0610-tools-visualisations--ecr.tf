resource "aws_ecr_repository" "user_provided" {
  name = "${var.prefix}-user-provided"
}

resource "aws_ecr_lifecycle_policy" "user_provided_expire_untagged_after_one_day" {
  repository = aws_ecr_repository.user_provided.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_preview_and_untagged_after_one_day.json
}

data "aws_ecr_lifecycle_policy_document" "expire_preview_and_untagged_after_one_day" {
  # Match *--prod images, but expire them in 1000 years...
  rule {
    priority = 1
    selection {
      tag_status       = "tagged"
      tag_pattern_list = ["*--prod"]
      count_type       = "sinceImagePushed"
      count_unit       = "days"
      count_number     = 365000
    }
  }
  # ... and images that don't match *--prod, but have "*--*" are "preview" and we expire them 1 day
  # after they have been pushed
  rule {
    priority = 2
    selection {
      tag_status       = "tagged"
      tag_pattern_list = ["*--*"]
      count_type       = "sinceImagePushed"
      count_unit       = "days"
      count_number     = 1
    }
  }
  # ... and just in case we somehow end up with untagged images, expire them after 1 day as well
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

data "aws_ecr_lifecycle_policy_document" "visualisation_base_expire_old_after_one_day" {
  # Match tagged python, but expire them in 1000 years...
  rule {
    priority = 1
    selection {
      tag_status       = "tagged"
      tag_pattern_list = ["python"]
      count_type       = "sinceImagePushed"
      count_unit       = "days"
      count_number     = 365000
    }
  }
  # otherwise match tagged rv4, but expire them in 1000 years...
  rule {
    priority = 2
    selection {
      tag_status       = "tagged"
      tag_pattern_list = ["rv4"]
      count_type       = "sinceImagePushed"
      count_unit       = "days"
      count_number     = 365000
    }
  }
  # ... and images that don't match python or rv4, but have a tag, are cached layers
  rule {
    priority = 3
    selection {
      tag_status       = "tagged"
      tag_pattern_list = ["*"]
      count_type       = "sinceImagePushed"
      count_unit       = "days"
      count_number     = 1
    }
  }
  # ... and for when we end up with untagged images, expire them after 1 day as well
  rule {
    priority = 4
    selection {
      tag_status   = "untagged"
      count_type   = "sinceImagePushed"
      count_unit   = "days"
      count_number = 1
    }
  }
}

data "aws_ecr_lifecycle_policy_document" "expire_non_master_non_latest_after_one_day" {
  # Match tagged master, but expire them in 1000 years...
  rule {
    priority = 1
    selection {
      tag_status       = "tagged"
      tag_pattern_list = ["master"]
      count_type       = "sinceImagePushed"
      count_unit       = "days"
      count_number     = 365000
    }
  }
  # otherwise match tagged latest, but expire them in 1000 years...
  rule {
    priority = 2
    selection {
      tag_status       = "tagged"
      tag_pattern_list = ["latest"]
      count_type       = "sinceImagePushed"
      count_unit       = "days"
      count_number     = 365000
    }
  }
  # ... and images that don't match python or rv4, but have a tag, are cached layers
  rule {
    priority = 3
    selection {
      tag_status       = "tagged"
      tag_pattern_list = ["*"]
      count_type       = "sinceImagePushed"
      count_unit       = "days"
      count_number     = 1
    }
  }
  # ... and for when we end up with untagged images, expire them after 1 day as well
  rule {
    priority = 4
    selection {
      tag_status   = "untagged"
      count_type   = "sinceImagePushed"
      count_unit   = "days"
      count_number = 1
    }
  }
}
