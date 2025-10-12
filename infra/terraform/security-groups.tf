locals {
    sg_tags = {
        Project = var.project_name
        Env = "dev"
    }
}

# --- WEB SG (pública): HTTP/HTTPS desde Internet, SSH solo desde tu IP ---
resource "aws_security_group" "web" {
  name        = "${var.project_name}-web-sg"
  description = "Allow HTTP/HTTPS from Internet; SSH from allowed CIDR"
  vpc_id      = aws_vpc.main.id
  tags        = merge(local.sg_tags, { Name = "${var.project_name}-web-sg" })

  # Egress abierto para que Web pueda hablar con RDS/NFS (ellos restringen por SG)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# HTTP 80 desde Internet
resource "aws_vpc_security_group_ingress_rule" "web_http" {
  security_group_id = aws_security_group.web.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  description       = "Allow HTTP from Internet"
}

# HTTPS 443 desde Internet (si vas a usar TLS)
resource "aws_vpc_security_group_ingress_rule" "web_https" {
  security_group_id = aws_security_group.web.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  description       = "Allow HTTPS from Internet"
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

# --- WORKER SG (privada): SSH opcional; egress abierto ---
resource "aws_security_group" "worker" {
  name        = "${var.project_name}-worker-sg"
  description = "Worker in private subnet; SSH from admin IP (optional)"
  vpc_id      = aws_vpc.main.id
  tags        = merge(local.sg_tags, { Name = "${var.project_name}-worker-sg" })

  # Egress abierto (para hablar con RDS/NFS y updates internos si tuvieras NAT)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# SSH solo desde tu IP (puedes eliminarlo si administras por SSM)
resource "aws_vpc_security_group_ingress_rule" "worker_ssh" {
  security_group_id = aws_security_group.worker.id
  cidr_ipv4         = var.allowed_ssh_cidr
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  description       = "Allow SSH from admin IP (optional)"
}

# --- NFS SG (privada): NFS 2049 desde WEB y WORKER, SSH desde tu IP ---
resource "aws_security_group" "nfs" {
  name        = "${var.project_name}-nfs-sg"
  description = "NFS server security group"
  vpc_id      = aws_vpc.main.id
  tags        = merge(local.sg_tags, { Name = "${var.project_name}-nfs-sg" })

  # Egress abierto
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# NFS 2049 TCP desde WEB SG
resource "aws_vpc_security_group_ingress_rule" "nfs_tcp_from_web" {
  security_group_id            = aws_security_group.nfs.id
  referenced_security_group_id = aws_security_group.web.id
  from_port                    = var.nfs_port
  to_port                      = var.nfs_port
  ip_protocol                  = "tcp"
  description                  = "Allow NFS TCP from WEB"
}

# NFS 2049 UDP desde WEB SG
resource "aws_vpc_security_group_ingress_rule" "nfs_udp_from_web" {
  security_group_id            = aws_security_group.nfs.id
  referenced_security_group_id = aws_security_group.web.id
  from_port                    = var.nfs_port
  to_port                      = var.nfs_port
  ip_protocol                  = "udp"
  description                  = "Allow NFS UDP from WEB"
}

# Permitir todo el tráfico desde WEB (para servicios auxiliares de NFS)
resource "aws_vpc_security_group_ingress_rule" "nfs_all_from_web" {
  security_group_id            = aws_security_group.nfs.id
  referenced_security_group_id = aws_security_group.web.id
  from_port                    = 111
  to_port                      = 111
  ip_protocol                  = "tcp"
  description                  = "Allow RPC from WEB"
}

resource "aws_vpc_security_group_ingress_rule" "nfs_rpc_udp_from_web" {
  security_group_id            = aws_security_group.nfs.id
  referenced_security_group_id = aws_security_group.web.id
  from_port                    = 111
  to_port                      = 111
  ip_protocol                  = "udp"
  description                  = "Allow RPC UDP from WEB"
}

# NFS 2049 TCP desde WORKER SG
resource "aws_vpc_security_group_ingress_rule" "nfs_tcp_from_worker" {
  security_group_id            = aws_security_group.nfs.id
  referenced_security_group_id = aws_security_group.worker.id
  from_port                    = var.nfs_port
  to_port                      = var.nfs_port
  ip_protocol                  = "tcp"
  description                  = "Allow NFS TCP from WORKER"
}

# NFS 2049 UDP desde WORKER SG
resource "aws_vpc_security_group_ingress_rule" "nfs_udp_from_worker" {
  security_group_id            = aws_security_group.nfs.id
  referenced_security_group_id = aws_security_group.worker.id
  from_port                    = var.nfs_port
  to_port                      = var.nfs_port
  ip_protocol                  = "udp"
  description                  = "Allow NFS UDP from WORKER"
}

# RPC desde WORKER
resource "aws_vpc_security_group_ingress_rule" "nfs_rpc_from_worker" {
  security_group_id            = aws_security_group.nfs.id
  referenced_security_group_id = aws_security_group.worker.id
  from_port                    = 111
  to_port                      = 111
  ip_protocol                  = "tcp"
  description                  = "Allow RPC from WORKER"
}

resource "aws_vpc_security_group_ingress_rule" "nfs_rpc_udp_from_worker" {
  security_group_id            = aws_security_group.nfs.id
  referenced_security_group_id = aws_security_group.worker.id
  from_port                    = 111
  to_port                      = 111
  ip_protocol                  = "udp"
  description                  = "Allow RPC UDP from WORKER"
}

# SSH a NFS desde tu IP
resource "aws_vpc_security_group_ingress_rule" "nfs_ssh" {
  security_group_id = aws_security_group.nfs.id
  cidr_ipv4         = var.allowed_ssh_cidr
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  description       = "Allow SSH to NFS from admin IP"
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

# Permitir Redis (6379) desde WORKER hacia WEB
resource "aws_vpc_security_group_ingress_rule" "web_redis_from_worker" {
  security_group_id            = aws_security_group.web.id
  referenced_security_group_id = aws_security_group.worker.id
  from_port                    = 6379
  to_port                      = 6379
  ip_protocol                  = "tcp"
  description                  = "Allow Redis from WORKER"
}