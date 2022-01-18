output "ids" {
  description = "List of IDs of subnets"
  value       = aws_subnet.this.*.id
}

output "arns" {
  description = "List of ARNs of subnets"
  value       = aws_subnet.this.*.arn
}

output "cidr_blocks" {
  description = "List of cidr_blocks of subnets"
  value       = aws_subnet.this.*.cidr_block
}

output "ipv6_cidr_blocks" {
  description = "List of IPv6 cidr_blocks of subnets in an IPv6 enabled VPC"
  value       = aws_subnet.this.*.ipv6_cidr_block
}

output "network_acl_id" {
  description = "ID of the network ACL"
  value       = concat(aws_network_acl.this.*.id, [""])[0]
}

output "network_acl_arn" {
  description = "ARN of the network ACL"
  value       = concat(aws_network_acl.this.*.arn, [""])[0]
}
