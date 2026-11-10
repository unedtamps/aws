variable "cluster_name" {
  type        = string
  description = "EKS cluster name, used as a prefix for the VPN resources."
}

variable "vpc_id" {
  type        = string
  description = "VPC where the VPN server is deployed."
}

variable "subnet_id" {
  type        = string
  description = "Public subnet for the VPN server."
}

variable "client_cidr" {
  type        = string
  description = "CIDR assigned to OpenVPN clients. Must not overlap the VPC or the Kubernetes service CIDR."
  default     = "172.16.0.0/22"

  validation {
    condition     = can(cidrhost(var.client_cidr, 0))
    error_message = "client_cidr must be a valid IPv4 CIDR."
  }
}

variable "admin_cidrs" {
  type        = list(string)
  description = "Source CIDRs allowed to reach the OpenVPN UDP port."

  validation {
    condition = (
      length(var.admin_cidrs) > 0 &&
      alltrue([for cidr in var.admin_cidrs : can(cidrhost(cidr, 0))])
    )
    error_message = "Provide at least one valid CIDR for admin_cidrs."
  }
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type for the OpenVPN server."
  default     = "t4g.micro"
}

variable "architecture" {
  type        = string
  description = "AMI architecture. Use arm64 with Graviton instance types (t4g) and x86_64 otherwise."
  default     = "arm64"

  validation {
    condition     = contains(["arm64", "x86_64"], var.architecture)
    error_message = "architecture must be arm64 or x86_64."
  }
}
