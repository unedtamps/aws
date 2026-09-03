output "vpc_id" {
  description = "Application VPC ID"
  value       = aws_vpc.main.id
}

output "alb_dns_name" {
  description = "Application Load Balancer DNS name"
  value       = aws_lb.app.dns_name
}

output "target_group_arn" {
  description = "Application target group ARN"
  value       = aws_lb_target_group.app.arn
}

output "instance_private_ips" {
  description = "Private IP addresses of application instances"
  value = {
    app_1 = aws_instance.app_1.private_ip
    app_2 = aws_instance.app_2.private_ip
  }
}
