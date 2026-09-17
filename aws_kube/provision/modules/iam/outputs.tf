output "cluster_role_arn" {
  description = "IAM role ARN used by the EKS control plane."
  value       = aws_iam_role.eks_cluster.arn
}

output "node_role_arn" {
  description = "IAM role ARN used by the EKS managed node group."
  value       = aws_iam_role.eks_nodes.arn
}

output "vpc_cni_role_arn" {
  description = "IAM role ARN used by the VPC CNI through EKS Pod Identity."
  value       = aws_iam_role.eks_vpc_cni.arn
}

output "load_balancer_controller_role_arn" {
  description = "IAM role ARN used by the AWS Load Balancer Controller through EKS Pod Identity."
  value       = aws_iam_role.aws_load_balancer_controller.arn
}
