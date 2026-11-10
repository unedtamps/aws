output "cluster_security_group_id" {
  description = "Security group created by EKS and attached to the control plane ENIs and managed nodes."
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

output "load_balancer_controller_role_arn" {
  description = "IAM role ARN used by the AWS Load Balancer Controller through EKS Pod Identity."
  value       = aws_iam_role.aws_load_balancer_controller.arn
}
