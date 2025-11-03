# Subnet Group (RDS exige ≥2 subredes en AZ distintas)
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-dbsubnet"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  tags = {
    Name    = "${var.project_name}-dbsubnet"
    Project = var.project_name
  }
}

# (Opcional) Parameter Group básico para Postgres
resource "aws_db_parameter_group" "pg" {
  name        = "${var.project_name}-pg"
  family      = "postgres15"
  description = "Param group dev"

  # Activar loggings minímo
  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }
}

# Instancia RDS (modo dev, sin Multi-AZ)
resource "aws_db_instance" "main" {
  identifier        = "${var.project_name}-db"
  engine            = var.db_engine # "postgres"
  engine_version    = var.db_engine_version
  instance_class    = var.db_instance_class # db.t3.micro suficiente para dev
  allocated_storage = var.db_allocated_storage
  storage_type      = "gp3"

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false # privado
  multi_az               = false # sin HA (dev)
  port                   = var.db_port
  username               = var.db_username
  password               = var.db_password
  db_name                = var.db_name
  parameter_group_name   = aws_db_parameter_group.pg.name

  deletion_protection = false
  skip_final_snapshot = true
  apply_immediately   = true

  tags = {
    Name    = "${var.project_name}-rds"
    Project = var.project_name
    Env     = "dev"
  }
}
