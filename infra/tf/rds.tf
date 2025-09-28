# Usar subnets de la VPC por defecto para crear DB Subnet Group
resource "aws_db_subnet_group" "default" {
  name       = "${local.name_prefix}-db-subnet-group"
  subnet_ids = data.aws_subnet_ids.default_vpc_subnets.ids
  description = "DB subnet group for ${local.name_prefix}"
  tags = {
    Name = "${local.name_prefix}-db-subnet-group"
  }
}

resource "aws_db_instance" "postgres" {
  identifier              = var.db_identifier
  allocated_storage       = var.db_allocated_storage
  engine                  = "postgres"
  engine_version          = "13.7"
  instance_class          = var.db_instance_class
#   name                    = var.db_name
  username                = var.db_username
  password                = var.db_password
  parameter_group_name    = "default.postgres13"
  skip_final_snapshot     = true
  publicly_accessible     = true
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  db_subnet_group_name    = aws_db_subnet_group.default.name
  tags = {
    Name = "${local.name_prefix}-postgres"
  }

  deletion_protection = false
}
