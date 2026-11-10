output "public_ip" {
  description = "Elastic IP clients use as the OpenVPN remote."
  value       = aws_eip.vpn.public_ip
}

output "instance_id" {
  description = "VPN EC2 instance ID, used for SSM Session Manager."
  value       = aws_instance.vpn.id
}

output "primary_network_interface_id" {
  description = "Primary ENI used as the target of the VPN client route."
  value       = aws_instance.vpn.primary_network_interface_id
}

output "client_cidr" {
  description = "CIDR assigned to OpenVPN clients."
  value       = var.client_cidr
}
