# 1. 로드밸런서 본체 (EIP 사용 안 함!)
resource "aws_lb" "be_alb" {
  name               = "${var.project_name}-be-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id] # 퍼블릭 서브넷 사용

  tags = { Name = "${var.project_name}-be-alb" }
}

# 2. 타겟 그룹 (ECS 컨테이너가 배달될 목적지)
resource "aws_lb_target_group" "be_tg" {
  name        = "${var.project_name}-be-tg"
  port        = 8000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip" # Fargate 사용 시 필수

  health_check {
    path                = "/v1/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = { Name = "${var.project_name}-be-tg" }
}

# 3. HTTP → HTTPS 301 (Mixed Content 방지: 구형 http:// 링크도 ALB에서 즉시 승격)
resource "aws_lb_listener" "be_http" {
  load_balancer_arn = aws_lb.be_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
      host        = "#{host}"
      path        = "/#{path}"
      query       = "#{query}"
    }
  }
}

# 4. HTTPS 종단 — ECS 타겟 그룹은 기존과 동일(HTTP:8000)
resource "aws_lb_listener" "be_https" {
  load_balancer_arn = aws_lb.be_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate_validation.alb_api.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.be_tg.arn
  }

  depends_on = [aws_acm_certificate_validation.alb_api]
}