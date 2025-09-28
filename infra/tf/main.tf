provider "aws" {
  region = var.aws_region
}

# Obtener VPC por defecto (usada para security groups y subnets)
data "aws_vpc" "default" {
  default = true
}

# Subnets de la VPC por defecto
data "aws_subnet_ids" "default_vpc_subnets" {
  vpc_id = data.aws_vpc.default.id
}

# Buscar AMI Amazon Linux 2 más reciente
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