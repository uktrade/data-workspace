data "aws_ecr_lifecycle_policy_document" "expire_untagged_after_one_day" {
  rule {
    priority = 1
    selection {
      tag_status   = "untagged"
      count_type   = "sinceImagePushed"
      count_unit   = "days"
      count_number = 1
    }
  }
}

data "aws_ecr_lifecycle_policy_document" "expire_tagged_and_untagged" {
  template = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Retain latest tagged image"
        selection = {
          tagStatus   = "tagged"
          countType   = "imageCountMoreThan"
          countNumber = 1
        }
        action = {
          type = "retain"
        }
      },
      {
        rulePriority = 2
        description  = "Expire tagged images older than 7 days"
        selection = {
          tagStatus   = "tagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 3
        description  = "Expire untagged images older than 1 day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
