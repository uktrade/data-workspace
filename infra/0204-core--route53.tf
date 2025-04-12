data "aws_route53_zone" "aws_route53_zone" {
  provider = aws.route53
  name     = var.aws_route53_zone
}
