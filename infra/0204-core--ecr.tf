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
