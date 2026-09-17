resource "aws_eks_addon" "pod_identity_agent" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "eks-pod-identity-agent"

  tags = {
    Name = "${aws_eks_cluster.main.name}-pod-identity-agent"
  }
}

resource "aws_eks_pod_identity_association" "vpc_cni" {
  cluster_name    = aws_eks_cluster.main.name
  namespace       = "kube-system"
  service_account = "aws-node"
  role_arn        = var.vpc_cni_role_arn

  depends_on = [
    aws_eks_addon.pod_identity_agent,
  ]
}
