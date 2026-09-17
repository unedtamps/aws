output "nlb_dns_name" {
  description = "NLB DNS name."
  value       = module.lb.nlb_dns_name
}

output "traefik_target_group_arn" {
  description = "Target group ARN for TargetGroupBinding."
  value       = module.lb.traefik_target_group_arn
}

output "acm_certificate_arn" {
  description = "ACM certificate ARN."
  value       = module.acm.certificate_arn
}
