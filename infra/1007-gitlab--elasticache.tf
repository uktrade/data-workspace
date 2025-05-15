resource "aws_elasticache_cluster" "gitlab_redis" {
  count                = var.gitlab_on ? 1 : 0
  cluster_id           = "${var.prefix_short}-gitlab"
  engine               = "redis"
  node_type            = "cache.t2.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis5.0"
  engine_version       = "7.1"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.gitlab[count.index].name
  security_group_ids   = ["${aws_security_group.gitlab_redis[count.index].id}"]
  apply_immediately    = true
}

resource "aws_elasticache_subnet_group" "gitlab" {
  count      = var.gitlab_on ? 1 : 0
  name       = "${var.prefix_short}-gitlab"
  subnet_ids = aws_subnet.private_with_egress.*.id
}
