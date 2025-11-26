# Launch Template para instancias Web
resource "aws_launch_template" "web" {
  name_prefix   = "${var.project_name}-web-lt-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  key_name      = data.aws_key_pair.main.key_name

  iam_instance_profile {
    name = data.aws_iam_instance_profile.lab_instance_profile.name
  }

  vpc_security_group_ids = [aws_security_group.web.id]

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = var.instance_disk_size
      volume_type = "gp3"
    }
  }

  user_data = base64encode(templatefile("${path.module}/user_data/web.sh", {
    DB_HOST        = aws_db_instance.main.address
    DB_PORT        = var.db_port
    DB_USER        = var.db_username
    DB_PASSWORD    = var.db_password
    DB_NAME        = var.db_name
    DB_SSLMODE     = "require"
    JWT_SECRET     = var.jwt_secret
    S3_BUCKET_NAME = aws_s3_bucket.storage.id
    AWS_REGION     = var.aws_region
    SQS_QUEUE_URL  = aws_sqs_queue.video_processing.url
    SSM_BASE_PATH  = var.ssm_path
  }))

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name    = "${var.project_name}-web-asg"
      Project = var.project_name
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Launch Template para instancias Worker
# resource "aws_launch_template" "worker" {
#   name_prefix   = "${var.project_name}-worker-lt-"
#   image_id      = data.aws_ami.amazon_linux.id
#   instance_type = var.instance_type
#   key_name      = data.aws_key_pair.main.key_name

#   iam_instance_profile {
#     name = data.aws_iam_instance_profile.lab_instance_profile.name
#   }

#   vpc_security_group_ids = [aws_security_group.worker.id]

#   block_device_mappings {
#     device_name = "/dev/xvda"

#     ebs {
#       volume_size = var.instance_disk_size
#       volume_type = "gp3"
#     }
#   }

#   user_data = base64encode(templatefile("${path.module}/user_data/worker.sh", {
#     DB_HOST        = aws_db_instance.main.address
#     DB_PORT        = var.db_port
#     DB_USER        = var.db_username
#     DB_PASSWORD    = var.db_password
#     DB_NAME        = var.db_name
#     DB_SSLMODE     = "require"
#     JWT_SECRET     = var.jwt_secret
#     S3_BUCKET_NAME = aws_s3_bucket.storage.id
#     AWS_REGION     = var.aws_region
#     SQS_QUEUE_URL  = aws_sqs_queue.video_processing.url
#     SSM_BASE_PATH  = var.ssm_path
#   }))

#   tag_specifications {
#     resource_type = "instance"

#     tags = {
#       Name    = "${var.project_name}-worker-asg"
#       Project = var.project_name
#     }
#   }

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# Auto Scaling Group
resource "aws_autoscaling_group" "web" {
  name                = "${var.project_name}-web-asg"
  vpc_zone_identifier = [aws_subnet.public.id, aws_subnet.public_b.id]
  target_group_arns = [
    aws_lb_target_group.auth.arn,
    aws_lb_target_group.video.arn,
    aws_lb_target_group.voting.arn,
    aws_lb_target_group.ranking.arn,
    aws_lb_target_group.front.arn
  ]
  health_check_type         = "ELB"
  health_check_grace_period = 900
  min_size                  = 2
  max_size                  = 3
  desired_capacity          = 2

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  enabled_metrics = [
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupMinSize",
    "GroupMaxSize",
    "GroupTotalInstances"
  ]

  tag {
    key                 = "Name"
    value               = "${var.project_name}-web-asg"
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = var.project_name
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity]
  }
}

# resource "aws_autoscaling_group" "worker" {
#   name                = "${var.project_name}-worker-asg"
#   vpc_zone_identifier = [aws_subnet.private_a.id]
#   target_group_arns = [
#     aws_lb_target_group.auth.arn,
#     aws_lb_target_group.video.arn,
#     aws_lb_target_group.voting.arn,
#     aws_lb_target_group.ranking.arn,
#     aws_lb_target_group.front.arn
#   ]
#   health_check_type         = "ELB"
#   health_check_grace_period = 900
#   min_size                  = 2
#   max_size                  = 3
#   desired_capacity          = 2

#   launch_template {
#     id      = aws_launch_template.worker.id
#     version = "$Latest"
#   }

#   enabled_metrics = [
#     "GroupDesiredCapacity",
#     "GroupInServiceInstances",
#     "GroupMinSize",
#     "GroupMaxSize",
#     "GroupTotalInstances"
#   ]

#   tag {
#     key                 = "Name"
#     value               = "${var.project_name}-worker-asg"
#     propagate_at_launch = true
#   }

#   tag {
#     key                 = "Project"
#     value               = var.project_name
#     propagate_at_launch = true
#   }

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# Política de escalado basada en CPU
resource "aws_autoscaling_policy" "cpu_high" {
  name                   = "${var.project_name}-cpu-high"
  autoscaling_group_name = aws_autoscaling_group.web.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70.0
  }
}

# Política de escalado basada en número de requests por target
resource "aws_autoscaling_policy" "alb_request_count" {
  name                   = "${var.project_name}-alb-request-count"
  autoscaling_group_name = aws_autoscaling_group.web.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = "${aws_lb.main.arn_suffix}/${aws_lb_target_group.video.arn_suffix}"
    }
    target_value = 1000.0
  }
}

# resource "aws_autoscaling_policy" "worker_cpu_high" {
#   name                   = "${var.project_name}-worker-cpu-high"
#   autoscaling_group_name = aws_autoscaling_group.worker.name
#   policy_type            = "TargetTrackingScaling"

#   target_tracking_configuration {
#     predefined_metric_specification {
#       predefined_metric_type = "ASGAverageCPUUtilization"
#     }

#     # CPU promedio objetivo
#     target_value = 70.0
#   }
# }