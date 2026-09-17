data "aws_eks_cluster" "main" {
  name       = var.cluster_name
  depends_on = [module.eks]
}

data "aws_subnet" "nlb_public" {
  for_each = {
    a = module.networking.public_subnet_ids[0]
    b = module.networking.public_subnet_ids[1]
  }

  id = each.value
}

resource "aws_vpc_security_group_ingress_rule" "nlb_to_traefik" {
  for_each = data.aws_subnet.nlb_public

  security_group_id = data.aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
  cidr_ipv4         = each.value.cidr_block
  ip_protocol       = "tcp"
  from_port         = 8000
  to_port           = 8000
  description       = "Allow NLB traffic and health checks to Traefik"
}
