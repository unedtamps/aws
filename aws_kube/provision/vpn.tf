module "vpn" {
  source = "./modules/vpn"

  cluster_name  = var.cluster_name
  vpc_id        = module.networking.vpc_id
  subnet_id     = module.networking.public_subnet_ids[0]
  client_cidr   = var.vpn_client_cidr
  admin_cidrs   = var.vpn_admin_cidrs
  instance_type = var.vpn_instance_type
  architecture  = var.vpn_architecture
}

# Return path for VPN client traffic: replies from the EKS control plane ENIs
# (and the VPC resolver) must go back to the VPN server, not to the NAT gateway.
resource "aws_route" "vpn_clients" {
  route_table_id         = module.networking.private_route_table_id
  destination_cidr_block = var.vpn_client_cidr
  network_interface_id   = module.vpn.primary_network_interface_id
}
