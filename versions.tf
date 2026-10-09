terraform {
  backend "s3" {
    bucket       = "terraform-eff45a195c6d0e5050657f1f88"
    use_lockfile = true
    key          = "terraform.tfstate"
    region       = "us-east-1"
  }
  required_providers {
    aws = {
      version = ">=6.0"
      source  = "hashicorp/aws"
    }
  }
  required_version = ">=1.12"
}

provider "aws" {
  region = var.region
}
