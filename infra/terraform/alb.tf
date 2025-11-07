# Definición de Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public.id, aws_subnet.public_b.id]

  enable_deletion_protection = false
  enable_http2               = true

  tags = {
    Name    = "${var.project_name}-alb"
    Project = var.project_name
  }
}

# Target Group para Auth Service (puerto 8080)
resource "aws_lb_target_group" "auth" {
  name     = "${var.project_name}-auth-tg"
  port     = var.auth_service_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 10
    interval            = 30
    path                = "/api/auth/login"
    protocol            = "HTTP"
    matcher             = "200,400,405"
  }

  deregistration_delay = 30

  tags = {
    Name    = "${var.project_name}-auth-tg"
    Project = var.project_name
  }
}

# Target Group para Video Service (puerto 8081)
resource "aws_lb_target_group" "video" {
  name     = "${var.project_name}-video-tg"
  port     = var.video_service_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 10
    interval            = 30
    path                = "/api/videos"
    protocol            = "HTTP"
    matcher             = "200,401"
  }

  deregistration_delay = 30

  tags = {
    Name    = "${var.project_name}-video-tg"
    Project = var.project_name
  }
}

# Target Group para Voting Service (puerto 8082)
resource "aws_lb_target_group" "voting" {
  name     = "${var.project_name}-voting-tg"
  port     = var.voting_service_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 10
    interval            = 30
    path                = "/api/public/videos"
    protocol            = "HTTP"
    matcher             = "200"
  }

  deregistration_delay = 30

  tags = {
    Name    = "${var.project_name}-voting-tg"
    Project = var.project_name
  }
}

# Target Group para Ranking Service (puerto 8083)
resource "aws_lb_target_group" "ranking" {
  name     = "${var.project_name}-ranking-tg"
  port     = var.ranking_service_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 10
    interval            = 30
    path                = "/api/public/rankings"
    protocol            = "HTTP"
    matcher             = "200"
  }

  deregistration_delay = 30

  tags = {
    Name    = "${var.project_name}-ranking-tg"
    Project = var.project_name
  }
}

# Target Group para Frontend (puerto 8084)
resource "aws_lb_target_group" "front" {
  name     = "${var.project_name}-front-tg"
  port     = var.front_server_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 10
    interval            = 30
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
  }

  deregistration_delay = 30

  tags = {
    Name    = "${var.project_name}-front-tg"
    Project = var.project_name
  }
}

# Listener HTTP en puerto 80
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }
}

# Reglas de enrutamiento basadas en path

# /auth/* -> Auth Service
resource "aws_lb_listener_rule" "auth" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.auth.arn
  }

  condition {
    path_pattern {
      values = ["/auth*"]
    }
  }
}

# /videos/* -> Video Service
resource "aws_lb_listener_rule" "video" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 20

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.video.arn
  }

  condition {
    path_pattern {
      values = ["/videos*"]
    }
  }
}

# /votes/* -> Voting Service
resource "aws_lb_listener_rule" "voting" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 30

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.voting.arn
  }

  condition {
    path_pattern {
      values = ["/votes*"]
    }
  }
}

# /ranking/* -> Ranking Service
resource "aws_lb_listener_rule" "ranking" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 40

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ranking.arn
  }

  condition {
    path_pattern {
      values = ["/ranking*"]
    }
  }
}

# /* (default) -> Frontend
resource "aws_lb_listener_rule" "front" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 50

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.front.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}