output "nlb_dns_name" {
  description = "DNS name of the internet-facing NLB."
  value       = aws_lb.traefik.dns_name
}
output "traefik_target_group_arn" {
  value = aws_lb_target_group.traefik_http.arn
}
