resource "aws_s3_bucket" "chuks_bucket" {
  tags = {
    Name = "chuksmet"
  }
}

resource "aws_s3_bucket_versioning" "bucket_version" {
  bucket = aws_s3_bucket.chuks_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "chuks_encrypt" {
  bucket = aws_s3_bucket.chuks_bucket.id


  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_vpc" "chuks_vpc" {
  cidr_block = var.cidr_block

  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames
}

data "aws_availability_zones" "Azs" {
  state = "available"
}

resource "aws_subnet" "chuks_subnet" {
  vpc_id                  = aws_vpc.chuks_vpc.id
  count                   = var.preferred_number_of_subnets == null ? length(data.aws_availability_zones.Azs.names) : var.preferred_number_of_subnets
  cidr_block              = cidrsubnet(var.cidr_block, 8, count.index)
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.Azs.names[count.index]
}

