# IAM roles for EKS and its add-ons moved from module.iam to module.eks.
# These blocks move state only; they must not cause any resource replacement.
moved {
  from = module.iam.aws_iam_role.eks_cluster
  to   = module.eks.aws_iam_role.eks_cluster
}

moved {
  from = module.iam.aws_iam_role_policy_attachment.eks_cluster
  to   = module.eks.aws_iam_role_policy_attachment.eks_cluster
}

moved {
  from = module.iam.aws_iam_role.eks_nodes
  to   = module.eks.aws_iam_role.eks_nodes
}

moved {
  from = module.iam.aws_iam_role_policy_attachment.eks_nodes_worker
  to   = module.eks.aws_iam_role_policy_attachment.eks_nodes_worker
}

moved {
  from = module.iam.aws_iam_role_policy_attachment.eks_nodes_ecr
  to   = module.eks.aws_iam_role_policy_attachment.eks_nodes_ecr
}

moved {
  from = module.iam.aws_iam_role.eks_vpc_cni
  to   = module.eks.aws_iam_role.eks_vpc_cni
}

moved {
  from = module.iam.aws_iam_role_policy_attachment.eks_vpc_cni
  to   = module.eks.aws_iam_role_policy_attachment.eks_vpc_cni
}

moved {
  from = module.iam.aws_iam_role.aws_load_balancer_controller
  to   = module.eks.aws_iam_role.aws_load_balancer_controller
}

moved {
  from = module.iam.aws_iam_role_policy.aws_load_balancer_controller
  to   = module.eks.aws_iam_role_policy.aws_load_balancer_controller
}

moved {
  from = module.iam.aws_iam_role.eks_ebs_csi_controller
  to   = module.eks.aws_iam_role.eks_ebs_csi_controller
}

moved {
  from = module.iam.aws_iam_role_policy_attachment.eks_ebs_csi_controller
  to   = module.eks.aws_iam_role_policy_attachment.eks_ebs_csi_controller
}
