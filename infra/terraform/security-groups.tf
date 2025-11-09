locals {
  sg_tags = {
    Project = var.project_name
    Env     = "dev"
  }
}

# --- ALB SG: HTTP/HTTPS desde Internet ---
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Allow HTTP/HTTPS from Internet to ALB"
  vpc_id      = aws_vpc.main.id
  tags        = merge(local.sg_tags, { Name = "${var.project_name}-alb-sg" })

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  description       = "Allow HTTP from Internet to ALB"
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  description       = "Allow HTTPS from Internet to ALB"
}

# --- WEB SG (pública): HTTP/HTTPS desde ALB, SSH solo desde tu IP ---
resource "aws_security_group" "web" {
  name        = "${var.project_name}-web-sg"
  description = "Allow HTTP/HTTPS from Internet; SSH from allowed CIDR"
  vpc_id      = aws_vpc.main.id
  tags        = merge(local.sg_tags, { Name = "${var.project_name}-web-sg" })

  # Egress abierto para que Web pueda hablar con RDS
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc_security_group_ingress_rule" "web_http_from_alb" {
  security_group_id            = aws_security_group.web.id
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
  description                  = "Allow HTTP from ALB"
}

resource "aws_vpc_security_group_ingress_rule" "web_https_from_alb" {
  security_group_id            = aws_security_group.web.id
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  description                  = "Allow HTTPS from ALB"
}

# SSH solo desde tu IP
resource "aws_vpc_security_group_ingress_rule" "web_ssh" {
  security_group_id = aws_security_group.web.id
  cidr_ipv4         = var.allowed_ssh_cidr
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  description       = "Allow SSH from admin IP"
}

resource "aws_vpc_security_group_ingress_rule" "web_auth" {
  security_group_id            = aws_security_group.web.id
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = var.auth_service_port
  to_port                      = var.auth_service_port
  ip_protocol                  = "tcp"
  description                  = "Allow Auth from from ALB"
}

resource "aws_vpc_security_group_ingress_rule" "web_video" {
  security_group_id            = aws_security_group.web.id
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = var.video_service_port
  to_port                      = var.video_service_port
  ip_protocol                  = "tcp"
  description                  = "Allow Video from ALB"
}

resource "aws_vpc_security_group_ingress_rule" "web_voting" {
  security_group_id            = aws_security_group.web.id
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = var.voting_service_port
  to_port                      = var.voting_service_port
  ip_protocol                  = "tcp"
  description                  = "Allow Voting from ALB"
}

resource "aws_vpc_security_group_ingress_rule" "web_ranking" {
  security_group_id            = aws_security_group.web.id
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = var.ranking_service_port
  to_port                      = var.ranking_service_port
  ip_protocol                  = "tcp"
  description                  = "Allow Ranking from ALB"
}

# Puerto 8084 para la aplicación (Frontend)
resource "aws_vpc_security_group_ingress_rule" "web_front" {
  security_group_id            = aws_security_group.web.id
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = var.front_server_port
  to_port                      = var.front_server_port
  ip_protocol                  = "tcp"
  description                  = "Allow access to frontend application from ALB"
}

# --- WORKER SG (privada): SSH opcional; egress abierto ---
resource "aws_security_group" "worker" {
  name        = "${var.project_name}-worker-sg"
  description = "Worker in private subnet; SSH from admin IP (optional)"
  vpc_id      = aws_vpc.main.id
  tags        = merge(local.sg_tags, { Name = "${var.project_name}-worker-sg" })

  # Egress abierto (para hablar con RDS)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# SSH desde tu IP para administración directa
resource "aws_vpc_security_group_ingress_rule" "worker_ssh" {
  security_group_id = aws_security_group.worker.id
  cidr_ipv4         = var.allowed_ssh_cidr
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  description       = "Allow SSH from admin IP"
}

# --- RDS SG (privada): DB_PORT desde WEB y WORKER ---
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "RDS security group"
  vpc_id      = aws_vpc.main.id
  tags        = merge(local.sg_tags, { Name = "${var.project_name}-rds-sg" })

  # Egress abierto (RDS no suele necesitar, pero lo dejamos por simetría)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# DB desde WEB
resource "aws_vpc_security_group_ingress_rule" "rds_from_web" {
  security_group_id            = aws_security_group.rds.id
  referenced_security_group_id = aws_security_group.web.id
  from_port                    = var.db_port
  to_port                      = var.db_port
  ip_protocol                  = "tcp"
  description                  = "Allow DB from WEB"
}

# DB desde WORKER
resource "aws_vpc_security_group_ingress_rule" "rds_from_worker" {
  security_group_id            = aws_security_group.rds.id
  referenced_security_group_id = aws_security_group.worker.id
  from_port                    = var.db_port
  to_port                      = var.db_port
  ip_protocol                  = "tcp"
  description                  = "Allow DB from WORKER"
}