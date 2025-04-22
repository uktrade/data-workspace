###################################################################################################
# A module that creates ingress and egress security group rules connecting "clients" with
# "servers", avoiding the boilerplate of having to create both egress and ingress rules, and
# also allows multiple groups of related rules to be easily and clearly created.
#
# The "clients" are defined by security groups, and the "server" by security groups, prefix list
# IDs, or CIDRs.
#
# Following is a full/complex example: it creates all the rules neccessary for the
# aws_security_group.notebooks security group to make tcp 443 connections to a number of VPC
# endpoints.
#
# In total, assuming sagemaker_on is true, it results in nine security group rules, adding rules
# to both the client and server security groups (the number is odd because the prefix list IDs
# have no security group to create rules for).
#
# module "tools_outgoing_https_vpc_endpoints" {
#   source = "./modules/security_group_client_server_connections"
#
#   client_security_groups = [aws_security_group.notebooks]
#   server_security_groups = concat([
#     aws_security_group.ecr_api,
#     aws_security_group.ecr_dkr,
#     aws_security_group.cloudwatch,
#     ], var.sagemaker_on ? [
#     aws_security_group.sagemaker_vpc_endpoints_main[0]] : []
#   )
#   server_prefix_list_ids = [
#     aws_vpc_endpoint.s3.prefix_list_id
#   ]
#   ports = [443]
#
#   depends_on = [aws_vpc_peering_connection.jupyterhub]
# }
#
# In this particular case as well, the security groups are in different VPCs, so an explicit
# depends_on meta-argument is added to make sure the peering connection exists, otherwise adding
# the rules can fail.
#
###################################################################################################


#################
# Input variables

variable "client_security_groups" {
  description = "The security groups on the client-side of the connections - needing egress rules"
  type = list(object({
    id   = string
    name = string
  }))
}

variable "server_security_groups" {
  description = "The security groups on the server-side of the connections - needing ingress rules"
  type = list(object({
    id   = string
    name = string
  }))
  default = []
}

variable "server_ipv4_cidrs" {
  description = "The IPv4 CIDR ranges of the server-side of the connections"
  type        = list(string)
  default     = []
}

variable "server_prefix_list_ids" {
  description = "The IDs of the prefix lists on the server-side of the connections"
  type        = list(string)
  default     = []
}

variable "ports" {
  description = "The ports used by the connections"
  type        = list(number)
  default     = []
}

variable "protocol" {
  description = "The protocol used by the connections - tcp in almost all cases"
  type        = string
  default     = "tcp"
}


###########################################
# For servers specificed by security groups

locals {
  server_security_group_ports = {
    for tuple in setproduct(var.client_security_groups, var.server_security_groups, var.ports) : "${tuple[0].name}.${tuple[1].name}.${tuple[2]}" => {
      client_security_group_id   = tuple[0].id
      client_security_group_name = tuple[0].name
      server_security_group_id   = tuple[1].id
      server_security_group_name = tuple[1].name
      port                       = tuple[2]
    }
  }
}

resource "aws_vpc_security_group_egress_rule" "client_to_server_security_group" {
  for_each = local.server_security_group_ports

  ip_protocol                  = var.protocol
  security_group_id            = each.value.client_security_group_id
  referenced_security_group_id = each.value.server_security_group_id
  from_port                    = each.value.port
  to_port                      = each.value.port

  description = "${each.value.port}-to-${each.value.server_security_group_name}"
}

resource "aws_vpc_security_group_ingress_rule" "server_security_group_from_client" {
  for_each = local.server_security_group_ports

  security_group_id            = each.value.server_security_group_id
  referenced_security_group_id = each.value.client_security_group_id
  ip_protocol                  = var.protocol
  from_port                    = each.value.port
  to_port                      = each.value.port

  description = "${each.value.port}-from-${each.value.client_security_group_name}"
}

#################################
# For servers specificed by CIDRs

locals {
  server_cidr_ports = {
    for tuple in setproduct(var.client_security_groups, var.server_ipv4_cidrs, var.ports) : "${tuple[0].name}.${tuple[1]}.${tuple[2]}" => {
      client_security_group_id = tuple[0].id
      server_ipv4_cidr         = tuple[1]
      port                     = tuple[2]
    }
  }
}

resource "aws_vpc_security_group_egress_rule" "client_to_server_cidr" {
  for_each = local.server_cidr_ports

  security_group_id = each.value.client_security_group_id
  cidr_ipv4         = each.value.server_ipv4_cidr
  ip_protocol       = var.protocol
  from_port         = each.value.port
  to_port           = each.value.port

  description = "${each.value.port}-to-${each.value.server_ipv4_cidr}"
}

########################################
# For servers specificed by prefix lists

locals {
  server_prefix_list_id_ports = {
    for tuple in setproduct(var.client_security_groups, var.server_prefix_list_ids, var.ports) : "${tuple[0].name}.${tuple[1]}.${tuple[2]}" => {
      client_security_group_id = tuple[0].id
      server_prefix_list_id    = tuple[1]
      port                     = tuple[2]
    }
  }
}

resource "aws_vpc_security_group_egress_rule" "client_to_server_prefix_list" {
  for_each = local.server_prefix_list_id_ports

  security_group_id = each.value.client_security_group_id
  prefix_list_id    = each.value.server_prefix_list_id
  ip_protocol       = var.protocol
  from_port         = each.value.port
  to_port           = each.value.port

  description = "${each.value.port}-to-${each.value.server_prefix_list_id}"
}
