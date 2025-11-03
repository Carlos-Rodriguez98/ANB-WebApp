variable "instance_disk_size" {
  default = 30
}

# AMI de Amazon Linux 2023 (ajusta región si no es us-east-1)
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# --- EC2 Web ---
resource "aws_instance" "web" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.web.id]
  key_name                    = data.aws_key_pair.main.key_name
  associate_public_ip_address = true
  iam_instance_profile        = data.aws_iam_instance_profile.lab_instance_profile.name

  root_block_device {
    volume_size = var.instance_disk_size
    volume_type = "gp3"
  }

  user_data = templatefile("${path.module}/user_data/web.sh", {
    DB_HOST        = aws_db_instance.main.address
    DB_PORT        = var.db_port
    DB_USER        = var.db_username
    DB_PASSWORD    = var.db_password
    DB_NAME        = var.db_name
    DB_SSLMODE     = "require"
    JWT_SECRET     = var.jwt_secret
    S3_BUCKET_NAME = aws_s3_bucket.storage.id
    AWS_REGION     = var.aws_region
    REDIS_ADDR     = "anbapp-redis:6379"
    REDIS_PORT     = "6379"
    SSM_BASE_PATH  = var.ssm_path
  })

  tags = {
    Name    = "${var.project_name}-web"
    Project = var.project_name
  }
}

# --- EC2 Worker ---
resource "aws_instance" "worker" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private_a.id
  vpc_security_group_ids = [aws_security_group.worker.id]
  key_name               = data.aws_key_pair.main.key_name
  iam_instance_profile   = data.aws_iam_instance_profile.lab_instance_profile.name

  root_block_device {
    volume_size = var.instance_disk_size
    volume_type = "gp3"
  }

  user_data = templatefile("${path.module}/user_data/worker.sh", {
    DB_HOST        = aws_db_instance.main.address
    DB_PORT        = var.db_port
    DB_USER        = var.db_username
    DB_PASSWORD    = var.db_password
    DB_NAME        = var.db_name
    DB_SSLMODE     = "require"
    JWT_SECRET     = var.jwt_secret
    S3_BUCKET_NAME = aws_s3_bucket.storage.id
    AWS_REGION     = var.aws_region
    REDIS_ADDR     = "${aws_instance.web.private_ip}:6379"
    REDIS_PORT     = "6379"
    SSM_BASE_PATH  = var.ssm_path
  })

  tags = {
    Name    = "${var.project_name}-worker"
    Project = var.project_name
  }
}
