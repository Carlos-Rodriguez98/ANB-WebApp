terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Definir VPC (usada para security groups y subnets)
resource "aws_vpc" "main" {
	cidr_block = "10.0.0.0/16"
	tags = { Name = "${var.project_name}-vpc" }
	enable_dns_hostnames = true
	enable_dns_support   = true
}

# Subnet de la VPC
data "aws_availability_zones" "available" {
	state = "available"
}
resource "aws_subnet" "public" {
	vpc_id = aws_vpc.main.id
	cidr_block = "10.0.1.0/24"
	map_public_ip_on_launch = true
	availability_zone = data.aws_availability_zones.available.names[0]
	tags = { Name = "${var.project_name}-public-subnet" }
}

# Subnets privadas para RDS
resource "aws_subnet" "private_a" {
	vpc_id = aws_vpc.main.id
	cidr_block = "10.0.2.0/24"
	availability_zone = data.aws_availability_zones.available.names[0]
	tags = { Name = "${var.project_name}-private-subnet-a" }
}
resource "aws_subnet" "private_b" {
	vpc_id = aws_vpc.main.id
	cidr_block = "10.0.3.0/24"
	availability_zone = data.aws_availability_zones.available.names[1]
	tags = { Name = "${var.project_name}-private-subnet-b" }
}

# Internet Gateway para la VPC
resource "aws_internet_gateway" "igw" {
	vpc_id = aws_vpc.main.id
	tags = { Name = "${var.project_name}-igw" }
}

# Route table para la subnet pública
resource "aws_route_table" "public" {
	vpc_id = aws_vpc.main.id
	tags = { Name = "${var.project_name}-public-rt" }
	# route {
		# cidr_block = "0.0.0.0/0"
		# gateway_id = aws_internet_gateway.igw.id
		# instance_id = null
		# nat_gateway_id = null
	# }
}
# resource "aws_route" "internet_access" {
# 	route_table_id         = aws_route_table.public.id
# 	destination_cidr_block = "0.0.0.0/0"
# 	gateway_id             = aws_internet_gateway.igw.id
# }
resource "aws_route_table_association" "public_assoc" {
	subnet_id      = aws_subnet.public.id
	route_table_id = aws_route_table.public.id
}

# Subnet group para RDS
resource "aws_db_subnet_group" "rds" {
  name       = "${var.project_name}-rds-subnet-group"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  tags = { Name = "${var.project_name}-rds-subnet-group" }
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