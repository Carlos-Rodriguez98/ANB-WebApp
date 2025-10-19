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
# resource "aws_instance" "web" {
#   ami           = data.aws_ami.amazon_linux.id
#   instance_type = var.instance_type
#   subnet_id     = aws_subnet.public.id
#   vpc_security_group_ids = [aws_security_group.web.id]
#   key_name      = data.aws_key_pair.main.key_name
#   associate_public_ip_address = true
#   iam_instance_profile = data.aws_iam_instance_profile.lab_instance_profile.name

#   root_block_device {
#     volume_size = var.instance_disk_size
#     volume_type = "gp3"
#   }

#   user_data = templatefile("${path.module}/user_data/web.sh", {
#     DB_HOST           = aws_db_instance.main.address
#     DB_PORT           = var.db_port
#     DB_USER           = var.db_username
#     DB_PASSWORD       = var.db_password
#     DB_NAME           = var.db_name
#     DB_SSLMODE        = "require"
#     JWT_SECRET        = var.jwt_secret
#     STORAGE_BASE_PATH = var.storage_base_path
#     NFS_SERVER        = aws_instance.nfs.private_ip
#     REDIS_ADDR        = "anbapp-redis:6379"
#     REDIS_PORT        = "6379"
#     SSM_BASE_PATH     = var.ssm_path
#   })

#   tags = {
#     Name    = "${var.project_name}-web"
#     Project = var.project_name
#   }
# }

# Replace the single aws_instance with a Launch Template.
# Define an Auto Scaling Group (ASG) that uses this template/configuration.
# Set the desired, min, and max instance counts.
resource "aws_launch_template" "web_lt" {
  name_prefix            = "${var.project_name}-web-lt-"
  image_id               = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name               = data.aws_key_pair.main.key_name
  vpc_security_group_ids = [aws_security_group.web.id]

  iam_instance_profile {
    name = data.aws_iam_instance_profile.lab_instance_profile.name
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = var.instance_disk_size
      volume_type = "gp3"
    }
  }

  user_data = base64encode(templatefile("${path.module}/user_data/web.sh", {
    DB_HOST           = aws_db_instance.main.address
    DB_PORT           = var.db_port
    DB_USER           = var.db_username
    DB_PASSWORD       = var.db_password
    DB_NAME           = var.db_name
    DB_SSLMODE        = "require"
    JWT_SECRET        = var.jwt_secret
    STORAGE_BASE_PATH = var.storage_base_path
    S3_BUCKET_NAME    = "anbapp-uploads-bucket"
    S3_PREFIX         = "videos"
    NFS_SERVER        = aws_instance.nfs.private_ip
    REDIS_ADDR        = "anbapp-redis:6379"
    REDIS_PORT        = "6379"
    SSM_BASE_PATH     = var.ssm_path
  }))

  tags = {
    Name    = "${var.project_name}-web"
    Project = var.project_name
  }
}

resource "aws_autoscaling_group" "web_asg" {
  name_prefix = "${var.project_name}-web-asg-"
  launch_template {
    id      = aws_launch_template.web_lt.id
    version = "$Latest"
  }
  vpc_zone_identifier = [aws_subnet.public.id]
  desired_capacity    = 1
  min_size            = 1
  max_size            = 3

  tag {
    key                 = "Name"
    value               = "${var.project_name}-web"
    propagate_at_launch = true
  }
  force_delete = true
}

# Create security group for ALB
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Allow HTTP/HTTPS inbound traffic to ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create ALB
resource "aws_lb" "web" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public.id, aws_subnet.public_b.id]
}

# Create Target Group for ALB
resource "aws_lb_target_group" "web" {
  name     = "${var.project_name}-tg"
  port     = 8084
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  health_check {
    path                = "/index.html"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# Create Listener for ALB
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.web.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

resource "aws_autoscaling_attachment" "web_asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.web_asg.name
  lb_target_group_arn    = aws_lb_target_group.web.arn
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
    DB_HOST           = aws_db_instance.main.address
    DB_PORT           = var.db_port
    DB_USER           = var.db_username
    DB_PASSWORD       = var.db_password
    DB_NAME           = var.db_name
    DB_SSLMODE        = "require"
    JWT_SECRET        = var.jwt_secret
    STORAGE_BASE_PATH = var.storage_base_path
    NFS_SERVER        = aws_instance.nfs.private_ip
    REDIS_ADDR        = "anbapp-redis:6379"
    REDIS_PORT        = "6379"
    SSM_BASE_PATH     = var.ssm_path
  })

  tags = {
    Name    = "${var.project_name}-worker"
    Project = var.project_name
  }
}

# --- EC2 NFS ---
resource "aws_instance" "nfs" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private_b.id
  vpc_security_group_ids = [aws_security_group.nfs.id]
  key_name               = data.aws_key_pair.main.key_name
  iam_instance_profile   = data.aws_iam_instance_profile.lab_instance_profile.name

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
