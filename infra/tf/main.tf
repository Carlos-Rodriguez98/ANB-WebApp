terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
	local = {
	  source  = "hashicorp/local"
	  version = "~> 2.0"
  	}
  }
}

provider "aws" {
  region = var.aws_region
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

# Descomentar esto de aquí pa abajo para el segundo apply
data "aws_db_instance" "rds" {
  db_instance_identifier = aws_db_instance.postgres.id
}

locals {
  rds_endpoint      = data.aws_db_instance.rds.endpoint
  AUTH_SERVER_PORT  = "8080"
  VIDEO_SERVER_PORT = "8081"
  VOTING_SERVER_PORT = "8082"
  RANKING_SERVER_PORT = "8083"
  FRONT_SERVER_PORT = "8084"
  DB_USER           = "master"
  DB_PASSWORD       = "ANB-WebApp1234!"
  DB_NAME           = "anb-web-app-db"
  JWT_SECRET        = "clavesecreta"
}

resource "local_file" "docker_compose_web" {
  content  = templatefile(
    "${path.module}/../docker-compose-web.yml.tmpl",
    {
      rds_endpoint      = local.rds_endpoint,
      AUTH_SERVER_PORT  = local.AUTH_SERVER_PORT,
      VIDEO_SERVER_PORT = local.VIDEO_SERVER_PORT,
      VOTING_SERVER_PORT = local.VOTING_SERVER_PORT,
      RANKING_SERVER_PORT = local.RANKING_SERVER_PORT,
      FRONT_SERVER_PORT = local.FRONT_SERVER_PORT,
      DB_USER           = local.DB_USER,
      DB_PASSWORD       = local.DB_PASSWORD,
      DB_NAME           = local.DB_NAME,
      JWT_SECRET        = local.JWT_SECRET
    }
  )
  filename = "${path.module}/../docker-compose-web.yml"
}

resource "local_file" "env_file" {
  content  = templatefile("${path.module}/../.env.tmpl", { rds_endpoint = local.rds_endpoint })
  filename = "${path.module}/../.env"
}