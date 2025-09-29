# Security Group para EC2 (Web, Worker, Fileserver)
resource "aws_security_group" "ec2_sg" {
  name        = "${local.name_prefix}-ec2-sg"
  description = "Security group for EC2 instances (web/worker/fileserver) - default VPC"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0", aws_vpc.main.cidr_block]
	self = false
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0", aws_vpc.main.cidr_block]
	self = false
  }

  ingress {
	description = "HTTPS"
	from_port   = 443
	to_port     = 443
	protocol    = "tcp"
	cidr_blocks = ["0.0.0.0/0", aws_vpc.main.cidr_block]
	self = false
  }

  ingress {
    description = "NFS"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description = "Auth Service"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0", aws_vpc.main.cidr_block]
    self = false
  }

  ingress {
    description = "Voting Service"
    from_port   = 8082
    to_port     = 8082
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0", aws_vpc.main.cidr_block]
    self = false
  }

  ingress {
    description = "Ranking Service"
    from_port   = 8083
    to_port     = 8083
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0", aws_vpc.main.cidr_block]
    self = false
  }

  ingress {
    description = "Front Service"
    from_port   = 8084
    to_port     = 8084
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0", aws_vpc.main.cidr_block]
    self = false
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-ec2-sg"
  }
}

# Security Group para RDS (permitir acceso desde EC2 SG)
resource "aws_security_group" "rds_sg" {
  name        = "${local.name_prefix}-rds-sg"
  description = "Security group for RDS postgres"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Postgres from EC2 SG"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-rds-sg"
  }
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
}

resource "aws_route" "internet_access" {
	route_table_id         = aws_route_table.public.id
	destination_cidr_block = "0.0.0.0/0"
	gateway_id             = aws_internet_gateway.igw.id
}

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