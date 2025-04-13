resource "aws_cloudwatch_log_group" "vpc_main_flow_log" {
  name              = "${var.prefix}-vpc-main-flow-log"
  retention_in_days = "3653"
}

resource "aws_iam_role" "vpc_main_flow_log" {
  name               = "${var.prefix}-vpc-main-flow-log"
  assume_role_policy = data.aws_iam_policy_document.vpc_main_flow_log_vpc_flow_logs_assume_role.json
}

data "aws_iam_policy_document" "vpc_main_flow_log_vpc_flow_logs_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "vpc_main_flow_log" {
  name   = "${var.prefix}-vpc-main-flow-log"
  role   = aws_iam_role.vpc_main_flow_log.id
  policy = data.aws_iam_policy_document.vpc_main_flow_log.json
}

data "aws_iam_policy_document" "vpc_main_flow_log" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]

    resources = [
      "${aws_cloudwatch_log_group.vpc_main_flow_log.arn}:*",
    ]
  }
}

resource "aws_service_discovery_private_dns_namespace" "jupyterhub" {
  name        = "jupyterhub"
  description = "jupyterhub"
  vpc         = aws_vpc.main.id
}

resource "aws_route" "pcx_datasets_to_paas" {
  count                     = var.paas_cidr_block != "" ? 1 : 0
  route_table_id            = aws_route_table.datasets.id
  destination_cidr_block    = var.paas_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.datasets_to_paas[0].id
}

resource "aws_route" "pcx_datasets_to_main" {
  route_table_id            = aws_route_table.datasets.id
  destination_cidr_block    = aws_vpc.main.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.datasets_to_main.id
}

resource "aws_route" "pcx_datasets_to_notebooks" {
  route_table_id            = aws_route_table.datasets.id
  destination_cidr_block    = aws_vpc.notebooks.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.datasets_to_notebooks.id
}

resource "aws_route" "pcx_private_with_egress_to_datasets" {
  route_table_id            = aws_route_table.private_with_egress.id
  destination_cidr_block    = aws_vpc.datasets.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.datasets_to_main.id
}

resource "aws_route" "pcx_datasets_to_private_without_egress" {
  route_table_id            = aws_route_table.private_without_egress.id
  destination_cidr_block    = aws_vpc.datasets.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.datasets_to_notebooks.id
}

data "aws_iam_policy_document" "aws_datasets_endpoint_ecr" {
  # Contains policies for both ECR and DKR endpoints, as recommended

  dynamic "statement" {
    for_each = var.arango_on ? [0] : []
    content {
      principals {
        type        = "AWS"
        identifiers = ["*"]
      }

      principals {
        type        = "AWS"
        identifiers = ["${aws_iam_role.arango_task_execution[0].arn}"]
      }

      actions = [
        "ecr:GetAuthorizationToken",
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer"
      ]

      resources = [
        "*",
      ]
    }
  }
}

######################################
### New VPC & Subnet for SageMaker ###
######################################

resource "aws_vpc" "sagemaker" {
  count = var.sagemaker_on ? 1 : 0

  cidr_block           = var.vpc_sagemaker_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.prefix}-sagemaker"
  }

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_subnet" "sagemaker_private_without_egress" {
  count = var.sagemaker_on ? length(var.aws_availability_zones) : 0

  vpc_id            = aws_vpc.sagemaker[0].id
  cidr_block        = cidrsubnet(aws_vpc.sagemaker[0].cidr_block, var.vpc_sagemaker_subnets_num_bits, count.index)
  availability_zone = var.aws_availability_zones[count.index]

  tags = {
    Name = "${var.prefix}-sagemaker-private-without-egress-${var.aws_availability_zones_short[count.index]}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route_table" "sagemaker" {

  count = var.sagemaker_on ? 1 : 0

  vpc_id = aws_vpc.sagemaker[0].id
  tags = {
    Name = "${var.prefix}-sagemaker"
  }
}

resource "aws_main_route_table_association" "sagemaker" {
  count          = var.sagemaker_on ? 1 : 0
  vpc_id         = aws_vpc.sagemaker[0].id
  route_table_id = aws_route_table.sagemaker[0].id
}

resource "aws_route_table_association" "private_without_egress_sagemaker" {
  count          = var.sagemaker_on ? length(var.aws_availability_zones) : 0
  subnet_id      = aws_subnet.sagemaker_private_without_egress.*.id[count.index]
  route_table_id = aws_route_table.sagemaker[0].id
}

resource "aws_vpc_endpoint_route_table_association" "s3_sagemaker" {
  count           = var.sagemaker_on ? 1 : 0
  vpc_endpoint_id = aws_vpc_endpoint.sagemaker_s3[0].id
  route_table_id  = aws_route_table.sagemaker[0].id
}

#############################################
### Cloudwatch Logging for SageMaker VPC  ###
#############################################

resource "aws_flow_log" "sagemaker" {
  count           = var.sagemaker_on ? 1 : 0
  log_destination = aws_cloudwatch_log_group.vpc_sagemaker_flow_log[0].arn
  iam_role_arn    = aws_iam_role.vpc_sagemaker_flow_log[0].arn
  vpc_id          = aws_vpc.sagemaker[0].id
  traffic_type    = "ALL"
}

resource "aws_cloudwatch_log_group" "vpc_sagemaker_flow_log" {
  count             = var.sagemaker_on ? 1 : 0
  name              = "${var.prefix}-vpc-sagemaker-flow-log"
  retention_in_days = "3653"
}

resource "aws_iam_role" "vpc_sagemaker_flow_log" {
  count              = var.sagemaker_on ? 1 : 0
  name               = "${var.prefix}-vpc-sagemaker-flow-log"
  assume_role_policy = data.aws_iam_policy_document.vpc_sagemaker_flow_log_vpc_flow_logs_assume_role[0].json
}

data "aws_iam_policy_document" "vpc_sagemaker_flow_log_vpc_flow_logs_assume_role" {
  count = var.sagemaker_on ? 1 : 0
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

###################################################
## VPC Endpoints in SageMaker VPC (SNS, S3, ECR) ##
###################################################

resource "aws_vpc_endpoint" "sagemaker_s3" {
  count             = var.sagemaker_on ? 1 : 0
  vpc_id            = aws_vpc.sagemaker[0].id
  service_name      = "com.amazonaws.${data.aws_region.aws_region.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.sagemaker[0].id]
}

resource "aws_vpc_endpoint" "sagemaker_ecr_api_endpoint" {
  count              = var.sagemaker_on ? 1 : 0
  vpc_id             = aws_vpc.sagemaker[0].id
  service_name       = "com.amazonaws.eu-west-2.ecr.api"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = aws_subnet.sagemaker_private_without_egress.*.id
  security_group_ids = [aws_security_group.sagemaker_endpoints[0].id]
  tags = {
    Environment = var.prefix
    Name        = "sagemaker-ecr-api-endpoint"
  }
  private_dns_enabled = true
  policy              = data.aws_iam_policy_document.aws_sagemaker_endpoint_ecr[0].json
}

resource "aws_vpc_endpoint" "sagemaker_ecr_dkr_endpoint" {
  count              = var.sagemaker_on ? 1 : 0
  vpc_id             = aws_vpc.sagemaker[0].id
  service_name       = "com.amazonaws.eu-west-2.ecr.dkr"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = aws_subnet.sagemaker_private_without_egress.*.id
  security_group_ids = [aws_security_group.sagemaker_endpoints[0].id]
  tags = {
    Environment = var.prefix
    Name        = "sagemaker-ecr-dkr-endpoint"
  }
  private_dns_enabled = true
  policy              = data.aws_iam_policy_document.aws_sagemaker_endpoint_ecr[0].json
}


data "aws_iam_policy_document" "aws_sagemaker_endpoint_ecr" {
  count = var.sagemaker_on ? 1 : 0
  # Contains policies for both ECR and DKR endpoints, as recommended

  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer"
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_vpc_endpoint" "sns_endpoint_sagemaker" {
  count              = var.sagemaker_on ? 1 : 0
  vpc_id             = aws_vpc.sagemaker[0].id
  service_name       = "com.amazonaws.eu-west-2.sns"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = aws_subnet.sagemaker_private_without_egress.*.id
  security_group_ids = [aws_security_group.sagemaker_endpoints[0].id]
  tags = {
    Environment = var.prefix
    Name        = "sns-endpoint"
  }
  private_dns_enabled = true
  policy              = data.aws_iam_policy_document.sns_endpoint_policy[0].json
}


data "aws_iam_policy_document" "sns_endpoint_policy" {
  count = var.sagemaker_on ? 1 : 0
  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "SNS:Subscribe",
      "SNS:Receive",
      "SNS:Publish",
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_vpc_endpoint" "airflow_resource_endpoints" {
  count = length(var.airflow_resource_endpoints)

  vpc_endpoint_type          = "Resource"
  resource_configuration_arn = var.airflow_resource_endpoints[count.index].arn
  vpc_id                     = aws_vpc.main.id
  subnet_ids                 = aws_subnet.private_with_egress[*].id

  private_dns_enabled = true
  security_group_ids  = [aws_security_group.airflow_resource_endpoints[count.index].id]
}
