resource "aws_eks_access_entry" "dev" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = "arn:aws:iam::246830848520:user/dev"
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "dev_admin" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = aws_eks_access_entry.dev.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.dev]
}
