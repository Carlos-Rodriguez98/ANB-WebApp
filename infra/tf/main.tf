terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Obtener VPC por defecto (usada para security groups y subnets)
data "aws_vpc" "default" {
  default = true
}

# Subnets de la VPC por defecto
data "aws_subnets" "default_vpc_subnets" {
	filter {
	  name = "vpc-id"
	  values = [data.aws_vpc.default.id]
	}
}

# Buscar AMI Amazon Linux más reciente
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = [var.ec2_ami_filter_name]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}