variable "instance_type" {
  default = "t3.small"  # 2 vCPU, 2 GiB RAM
}

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
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name      = aws_key_pair.main.key_name
  associate_public_ip_address = true

  root_block_device {
    volume_size = var.instance_disk_size
    volume_type = "gp3"
  }

  user_data = file("${path.module}/user_data/web_worker.sh")

  tags = {
    Name    = "${var.project_name}-web"
    Project = var.project_name
  }
}

# --- EC2 Worker ---
resource "aws_instance" "worker" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.private_a.id
  vpc_security_group_ids = [aws_security_group.worker.id]
  key_name      = aws_key_pair.main.key_name

  root_block_device {
    volume_size = var.instance_disk_size
    volume_type = "gp3"
  }

  user_data = file("${path.module}/user_data/web_worker.sh")

  tags = {
    Name    = "${var.project_name}-worker"
    Project = var.project_name
  }
}

# --- EC2 NFS ---
resource "aws_instance" "nfs" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.private_b.id
  vpc_security_group_ids = [aws_security_group.nfs.id]
  key_name      = aws_key_pair.main.key_name

  root_block_device {
    volume_size = var.instance_disk_size
    volume_type = "gp3"
  }

  user_data = file("${path.module}/user_data/nfs.sh")

  tags = {
    Name    = "${var.project_name}-nfs"
    Project = var.project_name
  }
}
