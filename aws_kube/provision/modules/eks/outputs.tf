output "cluster_security_group_id" {
  description = "Security group created by EKS and attached to the control plane ENIs and managed nodes."
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}
