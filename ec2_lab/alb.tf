resource "aws_lb" "app" {
  name               = "load-1"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.subnet_3.id, aws_subnet.subnet_4.id]
}

resource "aws_lb_target_group" "app" {
  name        = "target-1"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.main.id

  health_check {
    path     = "/"
    protocol = "HTTP"
    port     = "traffic-port"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

resource "aws_lb_target_group_attachment" "app_1" {
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = aws_instance.app_1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "app_2" {
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = aws_instance.app_2.id
  port             = 80
}
