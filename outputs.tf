output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.private_subnets.ids
}

output "private_subnet_arns" {
  description = "List of ARNs of private subnets"
  value       = module.private_subnets.arns
}

output "private_subnets_cidr_blocks" {
  description = "List of cidr_blocks of private subnets"
  value       = module.private_subnets.cidr_blocks
}

output "private_subnets_ipv6_cidr_blocks" {
  description = "List of IPv6 cidr_blocks of private subnets in an IPv6 enabled VPC"
  value       = module.private_subnets.ipv6_cidr_blocks
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.subnets["public"].ids
}

output "public_subnet_arns" {
  description = "List of ARNs of public subnets"
  value       = module.subnets["public"].arns
}

output "public_subnets_cidr_blocks" {
  description = "List of cidr_blocks of public subnets"
  value       = module.subnets["public"].cidr_blocks
}

output "public_subnets_ipv6_cidr_blocks" {
  description = "List of IPv6 cidr_blocks of public subnets in an IPv6 enabled VPC"
  value       = module.subnets["public"].ipv6_cidr_blocks
}

output "database_subnets" {
  description = "List of IDs of database subnets"
  value       = module.database_subnets.ids
}

output "database_subnet_arns" {
  description = "List of ARNs of database subnets"
  value       = module.database_subnets.arns
}

output "database_subnets_cidr_blocks" {
  description = "List of cidr_blocks of database subnets"
  value       = module.database_subnets.cidr_blocks
}

output "database_subnets_ipv6_cidr_blocks" {
  description = "List of IPv6 cidr_blocks of database subnets in an IPv6 enabled VPC"
  value       = module.database_subnets.ipv6_cidr_blocks
}

output "database_subnet_group" {
  description = "ID of database subnet group"
  value       = concat(aws_db_subnet_group.database.*.id, [""])[0]
}

output "database_subnet_group_name" {
  description = "Name of database subnet group"
  value       = concat(aws_db_subnet_group.database.*.name, [""])[0]
}

output "redshift_subnets" {
  description = "List of IDs of redshift subnets"
  value       = module.subnets["redshift"].ids
}

output "redshift_subnet_arns" {
  description = "List of ARNs of redshift subnets"
  value       = module.subnets["redshift"].arns
}

output "redshift_subnets_cidr_blocks" {
  description = "List of cidr_blocks of redshift subnets"
  value       = module.subnets["redshift"].cidr_blocks
}

output "redshift_subnets_ipv6_cidr_blocks" {
  description = "List of IPv6 cidr_blocks of redshift subnets in an IPv6 enabled VPC"
  value       = module.subnets["redshift"].ipv6_cidr_blocks
}

output "redshift_subnet_group" {
  description = "ID of redshift subnet group"
  value       = concat(aws_redshift_subnet_group.redshift.*.id, [""])[0]
}

output "elasticache_subnets" {
  description = "List of IDs of elasticache subnets"
  value       = module.elasticache_subnets.ids
}

output "elasticache_subnet_arns" {
  description = "List of ARNs of elasticache subnets"
  value       = module.elasticache_subnets.arns
}

output "elasticache_subnets_cidr_blocks" {
  description = "List of cidr_blocks of elasticache subnets"
  value       = module.elasticache_subnets.cidr_blocks
}

output "elasticache_subnets_ipv6_cidr_blocks" {
  description = "List of IPv6 cidr_blocks of elasticache subnets in an IPv6 enabled VPC"
  value       = module.elasticache_subnets.ipv6_cidr_blocks
}

output "intra_subnets" {
  description = "List of IDs of intra subnets"
  value       = module.intra_subnets.ids
}

output "intra_subnet_arns" {
  description = "List of ARNs of intra subnets"
  value       = module.intra_subnets.arns
}

output "intra_subnets_cidr_blocks" {
  description = "List of cidr_blocks of intra subnets"
  value       = module.intra_subnets.cidr_blocks
}

output "intra_subnets_ipv6_cidr_blocks" {
  description = "List of IPv6 cidr_blocks of intra subnets in an IPv6 enabled VPC"
  value       = module.intra_subnets.ipv6_cidr_blocks
}

output "elasticache_subnet_group" {
  description = "ID of elasticache subnet group"
  value       = concat(aws_elasticache_subnet_group.elasticache.*.id, [""])[0]
}

output "elasticache_subnet_group_name" {
  description = "Name of elasticache subnet group"
  value       = concat(aws_elasticache_subnet_group.elasticache.*.name, [""])[0]
}

output "public_route_table_ids" {
  description = "List of IDs of public route tables"
  value       = aws_route_table.public.*.id
}

output "private_route_table_ids" {
  description = "List of IDs of private route tables"
  value       = aws_route_table.private.*.id
}

output "database_route_table_ids" {
  description = "List of IDs of database route tables"
  value       = length(aws_route_table.database.*.id) > 0 ? aws_route_table.database.*.id : aws_route_table.private.*.id
}

output "redshift_route_table_ids" {
  description = "List of IDs of redshift route tables"
  value       = length(aws_route_table.redshift.*.id) > 0 ? aws_route_table.redshift.*.id : (var.enable_public_redshift ? aws_route_table.public.*.id : aws_route_table.private.*.id)
}

output "elasticache_route_table_ids" {
  description = "List of IDs of elasticache route tables"
  value       = length(aws_route_table.elasticache.*.id) > 0 ? aws_route_table.elasticache.*.id : aws_route_table.private.*.id
}

output "intra_route_table_ids" {
  description = "List of IDs of intra route tables"
  value       = aws_route_table.intra.*.id
}

output "public_internet_gateway_route_id" {
  description = "ID of the internet gateway route."
  value       = concat(aws_route.public_internet_gateway.*.id, [""])[0]
}

output "public_internet_gateway_ipv6_route_id" {
  description = "ID of the IPv6 internet gateway route."
  value       = concat(aws_route.public_internet_gateway_ipv6.*.id, [""])[0]
}

output "database_internet_gateway_route_id" {
  description = "ID of the database internet gateway route."
  value       = concat(aws_route.database_internet_gateway.*.id, [""])[0]
}

output "database_nat_gateway_route_ids" {
  description = "List of IDs of the database nat gateway route."
  value       = aws_route.database_nat_gateway.*.id
}

output "database_ipv6_egress_route_id" {
  description = "ID of the database IPv6 egress route."
  value       = concat(aws_route.database_ipv6_egress.*.id, [""])[0]
}

output "private_nat_gateway_route_ids" {
  description = "List of IDs of the private nat gateway route."
  value       = aws_route.private_nat_gateway.*.id
}

output "private_ipv6_egress_route_ids" {
  description = "List of IDs of the ipv6 egress route."
  value       = aws_route.private_ipv6_egress.*.id
}

output "private_route_table_association_ids" {
  description = "List of IDs of the private route table association"
  value       = aws_route_table_association.private.*.id
}

output "database_route_table_association_ids" {
  description = "List of IDs of the database route table association"
  value       = aws_route_table_association.database.*.id
}

output "redshift_route_table_association_ids" {
  description = "List of IDs of the redshift route table association"
  value       = aws_route_table_association.redshift.*.id
}

output "redshift_public_route_table_association_ids" {
  description = "List of IDs of the public redshidt route table association"
  value       = aws_route_table_association.redshift_public.*.id
}

output "elasticache_route_table_association_ids" {
  description = "List of IDs of the elasticache route table association"
  value       = aws_route_table_association.elasticache.*.id
}

output "intra_route_table_association_ids" {
  description = "List of IDs of the intra route table association"
  value       = aws_route_table_association.intra.*.id
}

output "public_route_table_association_ids" {
  description = "List of IDs of the public route table association"
  value       = aws_route_table_association.public.*.id
}

output "nat_ids" {
  description = "List of allocation ID of Elastic IPs created for AWS NAT Gateway"
  value       = aws_eip.nat.*.id
}

output "nat_public_ips" {
  description = "List of public Elastic IPs created for AWS NAT Gateway"
  value       = var.reuse_nat_ips ? var.external_nat_ips : aws_eip.nat.*.public_ip
}

output "natgw_ids" {
  description = "List of NAT Gateway IDs"
  value       = aws_nat_gateway.this.*.id
}

output "vgw_id" {
  description = "The ID of the VPN Gateway"
  value       = concat(aws_vpn_gateway.this.*.id, aws_vpn_gateway_attachment.this.*.vpn_gateway_id, [""])[0]
}

output "vgw_arn" {
  description = "The ARN of the VPN Gateway"
  value       = concat(aws_vpn_gateway.this.*.arn, [""])[0]
}

output "public_network_acl_id" {
  description = "ID of the public network ACL"
  value       = module.subnets["public"].network_acl_id
}

output "public_network_acl_arn" {
  description = "ARN of the public network ACL"
  value       = module.subnets["public"].network_acl_arn
}

output "private_network_acl_id" {
  description = "ID of the private network ACL"
  value       = module.private_subnets.network_acl_id
}

output "private_network_acl_arn" {
  description = "ARN of the private network ACL"
  value       = module.private_subnets.network_acl_arn
}

output "intra_network_acl_id" {
  description = "ID of the intra network ACL"
  value       = module.intra_subnets.network_acl_id
}

output "intra_network_acl_arn" {
  description = "ARN of the intra network ACL"
  value       = module.intra_subnets.network_acl_arn
}

output "database_network_acl_id" {
  description = "ID of the database network ACL"
  value       = module.database_subnets.network_acl_id
}

output "database_network_acl_arn" {
  description = "ARN of the database network ACL"
  value       = module.database_subnets.network_acl_arn
}

output "redshift_network_acl_id" {
  description = "ID of the redshift network ACL"
  value       = module.subnets["redshift"].network_acl_id
}

output "redshift_network_acl_arn" {
  description = "ARN of the redshift network ACL"
  value       = module.subnets["redshift"].network_acl_arn
}

output "elasticache_network_acl_id" {
  description = "ID of the elasticache network ACL"
  value       = module.elasticache_subnets.network_acl_id
}

output "elasticache_network_acl_arn" {
  description = "ARN of the elasticache network ACL"
  value       = module.elasticache_subnets.network_acl_arn
}

# VPC flow log
output "vpc_flow_log_id" {
  description = "The ID of the Flow Log resource"
  value       = concat(aws_flow_log.this.*.id, [""])[0]
}

output "vpc_flow_log_destination_arn" {
  description = "The ARN of the destination for VPC Flow Logs"
  value       = local.flow_log_destination_arn
}

output "vpc_flow_log_destination_type" {
  description = "The type of the destination for VPC Flow Logs"
  value       = var.flow_log_destination_type
}

output "vpc_flow_log_cloudwatch_iam_role_arn" {
  description = "The ARN of the IAM role used when pushing logs to Cloudwatch log group"
  value       = local.flow_log_iam_role_arn
}

# Static values (arguments)
output "azs" {
  description = "A list of availability zones specified as argument to this module"
  value       = var.azs
}

output "name" {
  description = "The name of the VPC specified as argument to this module"
  value       = var.name
}
