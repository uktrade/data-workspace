// We only ever deploy tagged images, so all ECR repos have a lifecycle policy to delete untagged
// images.
//
// Some repos also expire certain tagged images because they are either kaniko-generated cached
// layers, or no-longer deployed images

resource "aws_ecr_repository" "healthcheck" {
  name = "${var.prefix}-healthcheck"
}

resource "aws_ecr_lifecycle_policy" "healthcheck_expire_untagged_after_one_day" {
  repository = aws_ecr_repository.healthcheck.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_untagged_after_one_day.json
}

resource "aws_ecr_repository" "prometheus" {
  name = "${var.prefix}-prometheus"
}

resource "aws_ecr_lifecycle_policy" "prometheus_expire_untagged_after_one_day" {
  repository = aws_ecr_repository.prometheus.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_untagged_after_one_day.json
}

resource "aws_ecr_repository" "visualisation_base" {
  name = "${var.prefix}-visualisation-base"
}

resource "aws_ecr_lifecycle_policy" "visualisation_base_expire_old_after_one_day" {
  repository = aws_ecr_repository.visualisation_base.name
  policy     = data.aws_ecr_lifecycle_policy_document.visualisation_base_expire_old_after_one_day.json
}

resource "aws_ecr_repository" "mirrors_sync_cran_binary_rv4" {
  name = "${var.prefix}-mirrors-sync-cran-binary-rv4"
}

resource "aws_ecr_lifecycle_policy" "mirrors_sync_cran_binary_rv4_expire_non_master_non_latest_after_one_day" {
  repository = aws_ecr_repository.mirrors_sync_cran_binary_rv4.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_non_master_non_latest_after_one_day.json
}

resource "aws_ecr_repository" "superset" {
  name = "${var.prefix}-superset"
}

resource "aws_ecr_lifecycle_policy" "superset_expire_untagged_after_one_day" {
  repository = aws_ecr_repository.superset.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_untagged_after_one_day.json
}

resource "aws_ecr_repository" "flower" {
  name = "${var.prefix}-flower"
}

resource "aws_ecr_lifecycle_policy" "flower_expire_untagged_after_one_day" {
  repository = aws_ecr_repository.flower.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_untagged_after_one_day.json
}

resource "aws_ecr_repository" "mlflow" {
  name = "${var.prefix}-mlflow"
}

resource "aws_ecr_lifecycle_policy" "mlflow_expire_untagged_after_one_day" {
  repository = aws_ecr_repository.mlflow.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_untagged_after_one_day.json
}

resource "aws_ecr_repository" "matchbox" {
  count = var.matchbox_on ? 1 : 0
  name  = "${var.prefix}-matchbox"
}

resource "aws_ecr_repository" "datadog" {
  name = "${var.prefix}-datadog"
}

resource "aws_ecr_lifecycle_policy" "datadog_expire_untagged_after_one_day" {
  repository = aws_ecr_repository.datadog.name
  policy     = data.aws_ecr_lifecycle_policy_document.expire_untagged_after_one_day.json
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
