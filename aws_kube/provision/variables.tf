variable "cluster_name" {
  type        = string
  description = "Name of the EKS cluster."
  default     = "lab-eks"

  validation {
    condition     = can(regex("^[A-Za-z0-9][A-Za-z0-9_-]{0,99}$", var.cluster_name))
    error_message = "cluster_name must be 1-100 characters and contain only letters, numbers, hyphens, and underscores."
  }
}

variable "cluster_version" {
  type        = string
  description = "Kubernetes version for the EKS control plane."
  default     = "1.36"
}

variable "cluster_endpoint_public_access_cidrs" {
  type        = set(string)
  description = "CIDRs allowed to reach the public EKS Kubernetes API endpoint. Use your public IP as a /32."

  validation {
    condition = (
      length(var.cluster_endpoint_public_access_cidrs) > 0 &&
      alltrue([
        for cidr in var.cluster_endpoint_public_access_cidrs : can(cidrhost(cidr, 0))
      ])
    )
    error_message = "Provide at least one valid CIDR, preferably your public IP as a /32."
  }
}
