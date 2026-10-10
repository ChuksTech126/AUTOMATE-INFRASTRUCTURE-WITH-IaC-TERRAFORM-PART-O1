output "vpc_id" {
  value = aws_vpc.chuks_vpc.id
}

output "subnet_cidr" {
  value = aws_subnet.chuks_subnet[*].cidr_block
}

output "subnet_id" {
  value = aws_subnet.chuks_subnet[*].id
}