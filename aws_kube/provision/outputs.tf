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

output "aws_load_balancer_controller_role_arn" {
  description = "IAM role ARN used by the AWS Load Balancer Controller through EKS Pod Identity."
  value       = module.iam.load_balancer_controller_role_arn
}

output "external_secret_name" {
  value = module.secret.secret_name
}
output "external_secret_arn" {
  value = module.secret.secret_arn
}
