data "aws_vpc" "this" {
  id = var.vpc_id
}

resource "aws_subnet" "this" {
  count = length(var.subnets)

  vpc_id                          = var.vpc_id
  cidr_block                      = var.subnets[count.index]
  availability_zone               = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) > 0 ? element(var.azs, count.index) : null
  availability_zone_id            = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) == 0 ? element(var.azs, count.index) : null
  map_public_ip_on_launch         = var.map_public_ip_on_launch
  assign_ipv6_address_on_creation = var.assign_ipv6_address_on_creation

  ipv6_cidr_block = var.enable_ipv6 && length(var.subnet_ipv6_prefixes) > 0 ? cidrsubnet(data.aws_vpc.this.ipv6_cidr_block, 8, var.subnet_ipv6_prefixes[count.index]) : null

  tags = merge(
    {
      "Name" = format(
        "%s-%s-${var.subnet_suffix}-%s",
        data.aws_vpc.this.tags["Name"],
        var.name,
        element(var.azs, count.index),
      )
    },
    var.tags,
    var.subnet_tags,
  )
}

resource "aws_network_acl" "this" {
  count = var.dedicated_network_acl && length(var.subnets) > 0 ? 1 : 0

  vpc_id     = var.vpc_id
  subnet_ids = aws_subnet.this.*.id

  tags = merge(
    {
      "Name" = format("%s-${var.subnet_suffix}", var.name)
    },
    var.tags,
    var.acl_tags,
  )
}

resource "aws_network_acl_rule" "this_inbound" {
  count = var.dedicated_network_acl && length(var.subnets) > 0 ? length(var.inbound_acl_rules) : 0

  network_acl_id = aws_network_acl.this[0].id

  egress          = false
  rule_number     = var.inbound_acl_rules[count.index]["rule_number"]
  rule_action     = var.inbound_acl_rules[count.index]["rule_action"]
  from_port       = lookup(var.inbound_acl_rules[count.index], "from_port", null)
  to_port         = lookup(var.inbound_acl_rules[count.index], "to_port", null)
  icmp_code       = lookup(var.inbound_acl_rules[count.index], "icmp_code", null)
  icmp_type       = lookup(var.inbound_acl_rules[count.index], "icmp_type", null)
  protocol        = var.inbound_acl_rules[count.index]["protocol"]
  cidr_block      = lookup(var.inbound_acl_rules[count.index], "cidr_block", null)
  ipv6_cidr_block = lookup(var.inbound_acl_rules[count.index], "ipv6_cidr_block", null)
}

resource "aws_network_acl_rule" "this_outbound" {
  count = var.dedicated_network_acl && length(var.subnets) > 0 ? length(var.outbound_acl_rules) : 0

  network_acl_id = aws_network_acl.this[0].id

  egress          = true
  rule_number     = var.outbound_acl_rules[count.index]["rule_number"]
  rule_action     = var.outbound_acl_rules[count.index]["rule_action"]
  from_port       = lookup(var.outbound_acl_rules[count.index], "from_port", null)
  to_port         = lookup(var.outbound_acl_rules[count.index], "to_port", null)
  icmp_code       = lookup(var.outbound_acl_rules[count.index], "icmp_code", null)
  icmp_type       = lookup(var.outbound_acl_rules[count.index], "icmp_type", null)
  protocol        = var.outbound_acl_rules[count.index]["protocol"]
  cidr_block      = lookup(var.outbound_acl_rules[count.index], "cidr_block", null)
  ipv6_cidr_block = lookup(var.outbound_acl_rules[count.index], "ipv6_cidr_block", null)
}
