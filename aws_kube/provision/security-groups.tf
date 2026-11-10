data "aws_subnet" "nlb_public" {
  for_each = {
    a = module.networking.public_subnet_ids[0]
    b = module.networking.public_subnet_ids[1]
  }

  id = each.value
}

resource "aws_vpc_security_group_ingress_rule" "nlb_to_traefik" {
  for_each = data.aws_subnet.nlb_public

  security_group_id = module.eks.cluster_security_group_id
  cidr_ipv4         = each.value.cidr_block
  ip_protocol       = "tcp"
  from_port         = 8000
  to_port           = 8000
  description       = "Allow NLB traffic and health checks to Traefik"
}

resource "aws_security_group" "eks_api_vpn" {
  name_prefix = "${var.cluster_name}-eks-api-vpn-"
  description = "Allow the Kubernetes API from VPN clients only"
  vpc_id      = module.networking.vpc_id

  tags = {
    Name      = "${var.cluster_name}-eks-api-vpn"
    Project   = "aws-kube-lab"
    ManagedBy = "OpenTofu"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "eks_api_vpn" {
  security_group_id = aws_security_group.eks_api_vpn.id
  description       = "Kubernetes API from VPN clients"
  cidr_ipv4         = var.vpn_client_cidr
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}
