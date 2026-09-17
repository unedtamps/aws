resource "aws_eip" "nlb_a" {
  domain = "vpc"

  tags = {
    Name = "lab-eks-nlb-a"
  }
}

resource "aws_eip" "nlb_b" {
  domain = "vpc"

  tags = {
    Name = "lab-eks-nlb-b"
  }
}
resource "aws_lb" "traefik" {
  name               = "lab-eks-traefik"
  internal           = false
  load_balancer_type = "network"
  ip_address_type    = "ipv4"

  subnet_mapping {
    subnet_id     = var.public_subnet_ids[0]
    allocation_id = aws_eip.nlb_a.id
  }

  subnet_mapping {
    subnet_id     = var.public_subnet_ids[1]
    allocation_id = aws_eip.nlb_b.id
  }

  tags = {
    Name = "lab-eks-traefik"
  }
}

resource "aws_lb_target_group" "traefik_http" {
  name        = "lab-eks-traefik-http"
  port        = 80
  protocol    = "TCP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    protocol = "TCP"
    port     = "traffic-port"
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.traefik.arn
  port              = 443
  protocol          = "TLS"
  certificate_arn   = var.acm_certificate_arn
  ssl_policy        = var.ssl_policy

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.traefik_http.arn
  }
}
