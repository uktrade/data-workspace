resource "aws_iam_service_linked_role" "datasets_finder" {
  # This is a shared resource between all envs ... couldn't find a way to have
  # one per env as it automatically assigns the same name (and custom suffixes aren't
  # allowed for ES service linked roles).
  count            = var.datasets_create_elastic_aws_service_linked_role ? 1 : 0
  aws_service_name = "es.amazonaws.com"
}
