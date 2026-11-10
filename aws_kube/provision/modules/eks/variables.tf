variable "cluster_name" {
  type        = string
  description = "Name of the EKS cluster."
}

variable "cluster_version" {
  type        = string
  description = "Kubernetes version for the EKS control plane."
}

variable "cluster_endpoint_public_access" {
  type        = bool
  description = "Whether the public EKS Kubernetes API endpoint is enabled."
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  type        = set(string)
  description = "CIDRs allowed to reach the public EKS Kubernetes API endpoint."
}

variable "additional_security_group_ids" {
  type        = list(string)
  description = "Additional security groups attached to the EKS control plane ENIs."
  default     = []
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs used by the EKS cluster and node group."
}

variable "external_secret_role_arn" {
  type        = string
  description = "IAM role ARN used by External Secrets through EKS Pod Identity."
}
