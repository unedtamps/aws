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
  description = "AWS Secrets Manager name used by ExternalSecret remoteRef.key."
  value       = module.secret.secret_name
}
output "external_secret_arn" {
  description = "AWS Secrets Manager ARN used by the External Secrets IAM policy."
  value       = module.secret.secret_arn
}
output "vpc_id" {
  description = "VPC ID used by the Kubernetes platform chart."
  value       = module.networking.vpc_id
}

output "vpn_public_ip" {
  description = "Elastic IP of the OpenVPN server."
  value       = module.vpn.public_ip
}

output "vpn_instance_id" {
  description = "VPN EC2 instance ID for SSM Session Manager."
  value       = module.vpn.instance_id
}
