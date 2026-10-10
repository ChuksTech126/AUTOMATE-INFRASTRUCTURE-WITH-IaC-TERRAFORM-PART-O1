region = "us-east-1"

cidr_block = "172.16.0.0/16"

enable_dns_support = true

enable_dns_hostnames = true

preferred_number_of_subnets = 2

block_public_acls = true

block_public_policy = true

ignore_public_acls = true

restrict_public_buckets = true

aws_internet_gateway = "chuks_gateway"

aws_route_table = "chuks_route_table"
