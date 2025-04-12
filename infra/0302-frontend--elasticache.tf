resource "aws_elasticache_cluster" "admin" {
  cluster_id           = "${var.prefix_short}-admin"
  engine               = "redis"
  node_type            = "cache.t2.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis5.0"
  engine_version       = "5.0.6"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.admin.name
  security_group_ids   = ["${aws_security_group.admin_redis.id}"]
}

resource "aws_elasticache_subnet_group" "admin" {
  name       = "${var.prefix_short}-admin"
  subnet_ids = aws_subnet.private_with_egress.*.id
}
