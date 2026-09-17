output "vpc_id" {
  description = "VPC ID used by the EKS cluster."
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "Private subnet IDs used by the EKS cluster and node group."
  value = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id,
  ]
}
