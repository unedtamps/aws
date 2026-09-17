resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${aws_eks_cluster.main.name}-nodes"
  node_role_arn   = var.node_role_arn

  subnet_ids = var.private_subnet_ids

  ami_type       = "AL2023_x86_64_STANDARD"
  capacity_type  = "ON_DEMAND"
  disk_size      = 20
  instance_types = ["t3.small"]

  scaling_config {
    desired_size = 2
    min_size     = 2
    max_size     = 4
  }

  update_config {
    max_unavailable = 1
  }

  tags = {
    Name = "${aws_eks_cluster.main.name}-nodes"
  }

  depends_on = [
    aws_eks_pod_identity_association.vpc_cni,
  ]
}
