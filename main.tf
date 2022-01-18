module "subnet_cidr_az" {
  source = "hashicorp/subnets/cidr"

  base_cidr_block = var.cidr
  networks        = [for az in local.azs : { name = az, new_bits = ceil(log(length(local.azs) + 1, 2)) }]
}

module "subnet_cidr_type" {
  for_each = module.subnet_cidr_az.network_cidr_blocks
  source   = "hashicorp/subnets/cidr"

  base_cidr_block = each.value
  networks = [
    {
      name     = "public",
      new_bits = 6,
    },
    {
      name     = "private",
      new_bits = 2
    },
    {
      name     = null
      new_bits = 2
    },
    {
      name     = "database"
      new_bits = 6
    },
    {
      name     = "elasticache",
      new_bits = 6,
    },
    {
      name     = "kafka",
      new_bits = 6,
    },
    {
      name     = "elasticsearch",
      new_bits = 6,
    },
    {
      name     = null,
      new_bits = 4,
    },
    {
      name     = null,
      new_bits = 4,
    },
    {
      name     = null,
      new_bits = 5,
    },
    {
      name     = null
      new_bits = 6
    },
    {
      name     = "intra"
      new_bits = 6
    },
  ]
}

locals {
  max_subnet_length = max(
    length(var.private_subnets),
    length(var.elasticache_subnets),
    length(var.database_subnets),
    max([for k, v in var.subnets : length(v.subnets)]...),
  )
  nat_gateway_count = var.single_nat_gateway ? 1 : var.one_nat_gateway_per_az ? length(var.azs) : local.max_subnet_length
}

################################################################################
# VPC
################################################################################

data "aws_vpc" "this" {
  id = var.vpc_id
}

resource "aws_vpc_ipv4_cidr_block_association" "this" {
  vpc_id = var.vpc_id

  cidr_block = var.cidr
}

################################################################################
# Database routes
################################################################################

resource "aws_route_table" "database" {
  count = var.create_database_subnet_route_table && length(var.database_subnets) > 0 ? var.single_nat_gateway || var.create_database_internet_gateway_route ? 1 : length(var.database_subnets) : 0

  vpc_id = var.vpc_id

  tags = merge(
    {
      "Name" = var.single_nat_gateway || var.create_database_internet_gateway_route ? "${var.name}-${var.database_subnet_suffix}" : format(
        "%s-${var.database_subnet_suffix}-%s",
        var.name,
        element(var.azs, count.index),
      )
    },
    var.tags,
    var.database_route_table_tags,
  )
}

resource "aws_route" "database_internet_gateway" {
  count = var.create_database_subnet_route_table && length(var.database_subnets) > 0 && var.create_database_internet_gateway_route && false == var.create_database_nat_gateway_route ? 1 : 0

  route_table_id         = aws_route_table.database[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = var.gateway_id

  timeouts {
    create = "5m"
  }
}

resource "aws_route" "database_nat_gateway" {
  count = var.create_database_subnet_route_table && length(var.database_subnets) > 0 && false == var.create_database_internet_gateway_route && var.create_database_nat_gateway_route && var.enable_nat_gateway ? var.single_nat_gateway ? 1 : length(var.database_subnets) : 0

  route_table_id         = element(aws_route_table.database.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.this.*.id, count.index)

  timeouts {
    create = "5m"
  }
}

resource "aws_route" "database_ipv6_egress" {
  count = var.enable_ipv6 && var.create_database_subnet_route_table && length(var.database_subnets) > 0 && var.create_database_internet_gateway_route ? 1 : 0

  route_table_id              = aws_route_table.database[0].id
  destination_ipv6_cidr_block = "::/0"
  egress_only_gateway_id      = var.egress_only_gateway_id

  timeouts {
    create = "5m"
  }
}

################################################################################
# Redshift routes
################################################################################

resource "aws_route_table" "redshift" {
  count = var.create_redshift_subnet_route_table && length(var.subnets["redshift"].subnets) > 0 ? 1 : 0

  vpc_id = var.vpc_id

  tags = merge(
    {
      "Name" = "${var.name}-${var.subnets["redshift"].subnet_suffix}"
    },
    var.tags,
    var.redshift_route_table_tags,
  )
}

################################################################################
# Elasticache routes
################################################################################

resource "aws_route_table" "elasticache" {
  count = var.create_elasticache_subnet_route_table && length(var.elasticache_subnets) > 0 ? 1 : 0

  vpc_id = var.vpc_id

  tags = merge(
    {
      "Name" = "${var.name}-${var.elasticache_subnet_suffix}"
    },
    var.tags,
    var.elasticache_route_table_tags,
  )
}

################################################################################
# Intra routes
################################################################################

resource "aws_route_table" "intra" {
  count = length(var.intra_subnets) > 0 ? 1 : 0

  vpc_id = var.vpc_id

  tags = merge(
    {
      "Name" = "${var.name}-${var.intra_subnet_suffix}"
    },
    var.tags,
    var.intra_route_table_tags,
  )
}

################################################################################
# Public subnet
################################################################################

//module "public_subnets" {
//  source                          = "./subnet"
//  vpc_id                          = var.vpc_id
//  azs                             = var.azs
//  subnets                         = var.public_subnets
//  name                            = var.name
//  subnet_suffix                   = var.public_subnet_suffix
//  assign_ipv6_address_on_creation = var.public_subnet_assign_ipv6_address_on_creation == null ? var.assign_ipv6_address_on_creation : var.public_subnet_assign_ipv6_address_on_creation
//  subnet_ipv6_prefixes            = var.public_subnet_ipv6_prefixes
//  enable_ipv6                     = var.enable_ipv6
//  tags                            = var.tags
//  subnet_tags                     = var.public_subnet_tags
//  map_public_ip_on_launch         = var.map_public_ip_on_launch
//
//  dedicated_network_acl = var.public_dedicated_network_acl
//  inbound_acl_rules     = var.public_inbound_acl_rules
//  outbound_acl_rules    = var.public_outbound_acl_rules
//
//  depends_on = [
//    aws_vpc_ipv4_cidr_block_association.this
//  ]
//}

################################################################################
# Private subnet
################################################################################

module "private_subnets" {
  source                          = "./subnet"
  vpc_id                          = var.vpc_id
  azs                             = var.azs
  subnets                         = var.private_subnets
  name                            = var.name
  subnet_suffix                   = var.private_subnet_suffix
  assign_ipv6_address_on_creation = var.private_subnet_assign_ipv6_address_on_creation == null ? var.assign_ipv6_address_on_creation : var.private_subnet_assign_ipv6_address_on_creation
  subnet_ipv6_prefixes            = var.private_subnet_ipv6_prefixes
  enable_ipv6                     = var.enable_ipv6
  tags                            = var.tags
  subnet_tags                     = var.private_subnet_tags

  dedicated_network_acl = var.private_dedicated_network_acl
  inbound_acl_rules     = var.private_inbound_acl_rules
  outbound_acl_rules    = var.private_outbound_acl_rules

  depends_on = [
    aws_vpc_ipv4_cidr_block_association.this
  ]
}

################################################################################
# Arbitrary subnet
################################################################################
module "subnets" {
  for_each                        = var.subnets
  source                          = "./subnet"
  vpc_id                          = var.vpc_id
  azs                             = lookup(each.value, "azs", var.azs)
  subnets                         = lookup(each.value, "subnets", [])
  name                            = lookup(each.value, "name", var.name)
  subnet_suffix                   = coalesce(lookup(each.value, "subnet_suffix"), each.key)
  assign_ipv6_address_on_creation = lookup(each.value, "assign_ipv6_address_on_creation", var.assign_ipv6_address_on_creation)
  subnet_ipv6_prefixes            = coalesce(lookup(each.value, "subnet_ipv6_prefixes", null), [])
  enable_ipv6                     = lookup(each.value, "enable_ipv6", var.enable_ipv6)
  tags                            = lookup(each.value, "tags", var.tags)
  subnet_tags                     = lookup(each.value, "subnet_tags", {})
  map_public_ip_on_launch         = lookup(each.value, "map_public_ip_on_launch", false)

  dedicated_network_acl = coalesce(lookup(each.value, "dedicated_network_acl", null), false)
  inbound_acl_rules = coalesce(lookup(each.value, "inbound_acl_rules", null), [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    },
  ])
  outbound_acl_rules = coalesce(lookup(each.value, "outbound_acl_rules", null), [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    },
  ])

  depends_on = [
    aws_vpc_ipv4_cidr_block_association.this
  ]

}

################################################################################
# Database subnet
################################################################################

module "database_subnets" {
  source                          = "./subnet"
  vpc_id                          = var.vpc_id
  azs                             = var.azs
  subnets                         = var.database_subnets
  name                            = var.name
  subnet_suffix                   = var.database_subnet_suffix
  assign_ipv6_address_on_creation = var.database_subnet_assign_ipv6_address_on_creation == null ? var.assign_ipv6_address_on_creation : var.database_subnet_assign_ipv6_address_on_creation
  subnet_ipv6_prefixes            = var.database_subnet_ipv6_prefixes
  enable_ipv6                     = var.enable_ipv6
  tags                            = var.tags
  subnet_tags                     = var.database_subnet_tags

  dedicated_network_acl = var.database_dedicated_network_acl
  inbound_acl_rules     = var.database_inbound_acl_rules
  outbound_acl_rules    = var.database_outbound_acl_rules

  depends_on = [
    aws_vpc_ipv4_cidr_block_association.this
  ]
}

resource "aws_db_subnet_group" "database" {
  count = length(var.database_subnets) > 0 && var.create_database_subnet_group ? 1 : 0

  name        = lower(coalesce(var.database_subnet_group_name, var.name))
  description = "Database subnet group for ${var.name}"
  subnet_ids  = module.database_subnets.ids

  tags = merge(
    {
      "Name" = format("%s", lower(coalesce(var.database_subnet_group_name, var.name)))
    },
    var.tags,
    var.database_subnet_group_tags,
  )
}

################################################################################
# Redshift subnet
################################################################################

//module "redshift_subnets" {
//  source                          = "./subnet"
//  vpc_id                          = var.vpc_id
//  azs                             = var.azs
//  subnets                         = var.redshift_subnets
//  name                            = var.name
//  subnet_suffix                   = var.redshift_subnet_suffix
//  assign_ipv6_address_on_creation = var.redshift_subnet_assign_ipv6_address_on_creation == null ? var.assign_ipv6_address_on_creation : var.redshift_subnet_assign_ipv6_address_on_creation
//  subnet_ipv6_prefixes            = var.redshift_subnet_ipv6_prefixes
//  enable_ipv6                     = var.enable_ipv6
//  tags                            = var.tags
//  subnet_tags                     = var.redshift_subnet_tags
//
//  dedicated_network_acl = var.redshift_dedicated_network_acl
//  inbound_acl_rules     = var.redshift_inbound_acl_rules
//  outbound_acl_rules    = var.redshift_outbound_acl_rules
//
//  depends_on = [
//    aws_vpc_ipv4_cidr_block_association.this
//  ]
//}

resource "aws_redshift_subnet_group" "redshift" {
  count = length(var.subnets["redshift"].subnets) > 0 && var.create_redshift_subnet_group ? 1 : 0

  name        = lower(var.name)
  description = "Redshift subnet group for ${var.name}"
  subnet_ids  = module.subnets["redshift"].ids

  tags = merge(
    {
      "Name" = format("%s", var.name)
    },
    var.tags,
    var.redshift_subnet_group_tags,
  )
}

################################################################################
# ElastiCache subnet
################################################################################

module "elasticache_subnets" {
  source                          = "./subnet"
  vpc_id                          = var.vpc_id
  azs                             = var.azs
  subnets                         = var.elasticache_subnets
  name                            = var.name
  subnet_suffix                   = var.elasticache_subnet_suffix
  assign_ipv6_address_on_creation = var.elasticache_subnet_assign_ipv6_address_on_creation == null ? var.assign_ipv6_address_on_creation : var.elasticache_subnet_assign_ipv6_address_on_creation
  subnet_ipv6_prefixes            = var.elasticache_subnet_ipv6_prefixes
  enable_ipv6                     = var.enable_ipv6
  tags                            = var.tags
  subnet_tags                     = var.elasticache_subnet_tags

  dedicated_network_acl = var.elasticache_dedicated_network_acl
  inbound_acl_rules     = var.elasticache_inbound_acl_rules
  outbound_acl_rules    = var.elasticache_outbound_acl_rules

  depends_on = [
    aws_vpc_ipv4_cidr_block_association.this
  ]
}

resource "aws_elasticache_subnet_group" "elasticache" {
  count = length(var.elasticache_subnets) > 0 && var.create_elasticache_subnet_group ? 1 : 0

  name        = var.name
  description = "ElastiCache subnet group for ${var.name}"
  subnet_ids  = module.elasticache_subnets.ids
}

################################################################################
# Intra subnets - private subnet without NAT gateway
################################################################################

module "intra_subnets" {
  source                          = "./subnet"
  vpc_id                          = var.vpc_id
  azs                             = var.azs
  subnets                         = var.intra_subnets
  name                            = var.name
  subnet_suffix                   = var.intra_subnet_suffix
  assign_ipv6_address_on_creation = var.intra_subnet_assign_ipv6_address_on_creation == null ? var.assign_ipv6_address_on_creation : var.intra_subnet_assign_ipv6_address_on_creation
  subnet_ipv6_prefixes            = var.intra_subnet_ipv6_prefixes
  enable_ipv6                     = var.enable_ipv6
  tags                            = var.tags
  subnet_tags                     = var.intra_subnet_tags

  dedicated_network_acl = var.intra_dedicated_network_acl
  inbound_acl_rules     = var.intra_inbound_acl_rules
  outbound_acl_rules    = var.intra_outbound_acl_rules

  depends_on = [
    aws_vpc_ipv4_cidr_block_association.this
  ]
}

################################################################################
# Default Network ACLs
################################################################################

resource "aws_network_acl" "this" {
  vpc_id = var.vpc_id

  # The value of subnet_ids should be any subnet IDs that are not set as subnet_ids
  #   for any of the non-default network ACLs
  subnet_ids = setsubtract(
    compact(flatten([
      module.subnets["public"].ids,
      module.private_subnets.ids,
      module.intra_subnets.ids,
      module.database_subnets.ids,
      module.subnets["redshift"].ids,
      module.elasticache_subnets.ids,
    ])),
    compact(flatten([
      var.subnets["public"].dedicated_network_acl ? module.subnets["public"].ids : [],
      var.private_dedicated_network_acl ? module.private_subnets.ids : [],
      var.intra_dedicated_network_acl ? module.intra_subnets.ids : [],
      var.database_dedicated_network_acl ? module.database_subnets.ids : [],
      var.subnets["redshift"].dedicated_network_acl ? module.subnets["redshift"].ids : [],
      var.elasticache_dedicated_network_acl ? module.elasticache_subnets.ids : [],
    ]))
  )

  dynamic "ingress" {
    for_each = var.default_network_acl_ingress
    content {
      action          = ingress.value.action
      cidr_block      = lookup(ingress.value, "cidr_block", null)
      from_port       = ingress.value.from_port
      icmp_code       = lookup(ingress.value, "icmp_code", null)
      icmp_type       = lookup(ingress.value, "icmp_type", null)
      ipv6_cidr_block = lookup(ingress.value, "ipv6_cidr_block", null)
      protocol        = ingress.value.protocol
      rule_no         = ingress.value.rule_no
      to_port         = ingress.value.to_port
    }
  }
  dynamic "egress" {
    for_each = var.default_network_acl_egress
    content {
      action          = egress.value.action
      cidr_block      = lookup(egress.value, "cidr_block", null)
      from_port       = egress.value.from_port
      icmp_code       = lookup(egress.value, "icmp_code", null)
      icmp_type       = lookup(egress.value, "icmp_type", null)
      ipv6_cidr_block = lookup(egress.value, "ipv6_cidr_block", null)
      protocol        = egress.value.protocol
      rule_no         = egress.value.rule_no
      to_port         = egress.value.to_port
    }
  }

  tags = merge(
    {
      "Name" = format("%s", var.default_network_acl_name)
    },
    var.tags,
    var.default_network_acl_tags,
  )
}

################################################################################
# NAT Gateway
################################################################################

# Workaround for interpolation not being able to "short-circuit" the evaluation of the conditional branch that doesn't end up being used
# Source: https://github.com/hashicorp/terraform/issues/11566#issuecomment-289417805
#
# The logical expression would be
#
#    nat_gateway_ips = var.reuse_nat_ips ? var.external_nat_ip_ids : aws_eip.nat.*.id
#
# but then when count of aws_eip.nat.*.id is zero, this would throw a resource not found error on aws_eip.nat.*.id.
locals {
  nat_gateway_ips = split(
    ",",
    var.reuse_nat_ips ? join(",", var.external_nat_ip_ids) : join(",", aws_eip.nat.*.id),
  )
}

resource "aws_eip" "nat" {
  count = var.enable_nat_gateway && false == var.reuse_nat_ips ? local.nat_gateway_count : 0

  vpc = true

  tags = merge(
    {
      "Name" = format(
        "%s-%s",
        var.name,
        element(var.azs, var.single_nat_gateway ? 0 : count.index),
      )
    },
    var.tags,
    var.nat_eip_tags,
  )
}

resource "aws_nat_gateway" "this" {
  count = var.enable_nat_gateway ? local.nat_gateway_count : 0

  allocation_id = element(
    local.nat_gateway_ips,
    var.single_nat_gateway ? 0 : count.index,
  )
  subnet_id = element(
    module.subnets["public"].ids,
    var.single_nat_gateway ? 0 : count.index,
  )

  tags = merge(
    {
      "Name" = format(
        "%s-%s",
        var.name,
        element(var.azs, var.single_nat_gateway ? 0 : count.index),
      )
    },
    var.tags,
    var.nat_gateway_tags,
  )
}

resource "aws_route" "private_nat_gateway" {
  count = var.enable_nat_gateway ? local.nat_gateway_count : 0

  route_table_id         = element(aws_route_table.private.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.this.*.id, count.index)

  timeouts {
    create = "5m"
  }
}

resource "aws_route" "private_ipv6_egress" {
  count = var.enable_ipv6 ? length(var.private_subnets) : 0

  route_table_id              = element(aws_route_table.private.*.id, count.index)
  destination_ipv6_cidr_block = "::/0"
  egress_only_gateway_id      = var.egress_only_gateway_id
}

################################################################################
# Route table association
################################################################################

resource "aws_route_table_association" "private" {
  count = length(module.private_subnets.ids)

  subnet_id = element(module.private_subnets.ids, count.index)
  route_table_id = element(
    aws_route_table.private.*.id,
    var.single_nat_gateway ? 0 : count.index,
  )
}

resource "aws_route_table_association" "database" {
  count = length(module.database_subnets.ids)

  subnet_id = element(module.database_subnets.ids, count.index)
  route_table_id = element(
    coalescelist(aws_route_table.database.*.id, aws_route_table.private.*.id),
    var.create_database_subnet_route_table ? var.single_nat_gateway || var.create_database_internet_gateway_route ? 0 : count.index : count.index,
  )
}

resource "aws_route_table_association" "redshift" {
  count = length(module.subnets["redshift"].ids) > 0 && false == var.enable_public_redshift ? length(module.subnets["redshift"].ids) : 0

  subnet_id = element(module.subnets["redshift"].ids, count.index)
  route_table_id = element(
    coalescelist(aws_route_table.redshift.*.id, aws_route_table.private.*.id),
    var.single_nat_gateway || var.create_redshift_subnet_route_table ? 0 : count.index,
  )
}

resource "aws_route_table_association" "redshift_public" {
  count = length(module.subnets["redshift"].ids) > 0 && var.enable_public_redshift ? length(module.subnets["redshift"].ids) : 0

  subnet_id = element(module.subnets["redshift"].ids, count.index)
  route_table_id = element(
    coalescelist(aws_route_table.redshift.*.id, aws_route_table.public.*.id),
    var.single_nat_gateway || var.create_redshift_subnet_route_table ? 0 : count.index,
  )
}

resource "aws_route_table_association" "elasticache" {
  count = length(module.elasticache_subnets.ids)

  subnet_id = element(module.elasticache_subnets.ids, count.index)
  route_table_id = element(
    coalescelist(
      aws_route_table.elasticache.*.id,
      aws_route_table.private.*.id,
    ),
    var.single_nat_gateway || var.create_elasticache_subnet_route_table ? 0 : count.index,
  )
}

resource "aws_route_table_association" "intra" {
  count = length(module.intra_subnets.ids)

  subnet_id      = element(module.intra_subnets.ids, count.index)
  route_table_id = element(aws_route_table.intra.*.id, 0)
}

resource "aws_route_table_association" "public" {
  count = length(module.subnets["public"].ids)

  subnet_id      = element(module.subnets["public"].ids, count.index)
  route_table_id = aws_route_table.public[0].id
}

################################################################################
# VPN Gateway
################################################################################

resource "aws_vpn_gateway" "this" {
  count = var.enable_vpn_gateway ? 1 : 0

  vpc_id            = var.vpc_id
  amazon_side_asn   = var.amazon_side_asn
  availability_zone = var.vpn_gateway_az

  tags = merge(
    {
      "Name" = format("%s", var.name)
    },
    var.tags,
    var.vpn_gateway_tags,
  )
}

resource "aws_vpn_gateway_attachment" "this" {
  count = var.vpn_gateway_id != "" ? 1 : 0

  vpc_id         = var.vpc_id
  vpn_gateway_id = var.vpn_gateway_id
}

resource "aws_vpn_gateway_route_propagation" "public" {
  count = var.propagate_public_route_tables_vgw && (var.enable_vpn_gateway || var.vpn_gateway_id != "") ? 1 : 0

  route_table_id = element(aws_route_table.public.*.id, count.index)
  vpn_gateway_id = element(
    concat(
      aws_vpn_gateway.this.*.id,
      aws_vpn_gateway_attachment.this.*.vpn_gateway_id,
    ),
    count.index,
  )
}

resource "aws_vpn_gateway_route_propagation" "private" {
  count = var.propagate_private_route_tables_vgw && (var.enable_vpn_gateway || var.vpn_gateway_id != "") ? length(var.private_subnets) : 0

  route_table_id = element(aws_route_table.private.*.id, count.index)
  vpn_gateway_id = element(
    concat(
      aws_vpn_gateway.this.*.id,
      aws_vpn_gateway_attachment.this.*.vpn_gateway_id,
    ),
    count.index,
  )
}

resource "aws_vpn_gateway_route_propagation" "intra" {
  count = var.propagate_intra_route_tables_vgw && (var.enable_vpn_gateway || var.vpn_gateway_id != "") ? length(var.intra_subnets) : 0

  route_table_id = element(aws_route_table.intra.*.id, count.index)
  vpn_gateway_id = element(
    concat(
      aws_vpn_gateway.this.*.id,
      aws_vpn_gateway_attachment.this.*.vpn_gateway_id,
    ),
    count.index,
  )
}
