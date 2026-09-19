variable "cluster_name" {
  type        = string
  description = "Name of the EKS cluster."
}

variable "cluster_version" {
  type        = string
  description = "Kubernetes version for the EKS control plane."
}

variable "cluster_endpoint_public_access_cidrs" {
  type        = set(string)
  description = "CIDRs allowed to reach the public EKS Kubernetes API endpoint."
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs used by the EKS cluster and node group."
}

variable "cluster_role_arn" {
  type        = string
  description = "IAM role ARN used by the EKS control plane."
}

variable "node_role_arn" {
  type        = string
  description = "IAM role ARN used by the EKS managed node group."
}

variable "vpc_cni_role_arn" {
  type        = string
  description = "IAM role ARN used by the VPC CNI through EKS Pod Identity."
}

variable "load_balancer_controller_role_arn" {
  type        = string
  description = "IAM role ARN used by the AWS Load Balancer Controller through EKS Pod Identity."
}

variable "external_secret_role_arn" {
  type        = string
  description = "IAM role ARN used by the AWS Load Balancer Controller through EKS Pod Identity."

}
