output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_id" {
  value = module.vpc.public_subnet_id
}

output "private_subnet_id" {
  value = module.vpc.private_subnet_id
}

output "internet_gateway_id" {
  value = module.vpc.internet_gateway_id
}

output "nat_gateway_eip" {
  description = "Elastic IP cua NAT Gateway"
  value       = module.nat_gateway.eip_public_ip
}

output "public_ec2_public_ip" {
  description = "Public IP cua EC2 o Public Subnet – dung de SSH"
  value       = module.ec2.public_ec2_public_ip
}

output "private_ec2_private_ip" {
  description = "Private IP cua EC2 o Private Subnet"
  value       = module.ec2.private_ec2_private_ip
}