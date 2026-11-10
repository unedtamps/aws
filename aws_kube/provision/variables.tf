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

variable "cluster_endpoint_public_access" {
  type        = bool
  description = "Whether the public EKS Kubernetes API endpoint is enabled. Keep it true until the VPN path is verified, then set it to false."
  default     = false
}

variable "vpn_client_cidr" {
  type        = string
  description = "CIDR assigned to OpenVPN clients. Must not overlap 10.20.0.0/16 or the Kubernetes service CIDR."
  default     = "172.16.0.0/22"

  validation {
    condition     = can(cidrhost(var.vpn_client_cidr, 0))
    error_message = "vpn_client_cidr must be a valid IPv4 CIDR."
  }
}

variable "vpn_admin_cidrs" {
  type        = list(string)
  description = "Source CIDRs allowed to reach the OpenVPN UDP port (temporary admin IPs)."

  validation {
    condition = (
      length(var.vpn_admin_cidrs) > 0 &&
      alltrue([for cidr in var.vpn_admin_cidrs : can(cidrhost(cidr, 0))])
    )
    error_message = "Provide at least one valid CIDR for vpn_admin_cidrs."
  }
}

variable "vpn_instance_type" {
  type        = string
  description = "EC2 instance type for the OpenVPN server."
  default     = "t4g.micro"
}

variable "vpn_architecture" {
  type        = string
  description = "AMI architecture for the VPN instance. arm64 for t4g, x86_64 otherwise."
  default     = "arm64"

  validation {
    condition     = contains(["arm64", "x86_64"], var.vpn_architecture)
    error_message = "vpn_architecture must be arm64 or x86_64."
  }
}

variable "acm_domain_name" {
  type        = string
  description = "Domain name for the NLB TLS certificate."
}

variable "cloudflare_zone_id" {
  type        = string
  description = "Cloudflare zone ID for lensboxd.site."
}

variable "acm_subject_alternative_names" {
  type        = list(string)
  description = "Additional DNS names covered by the NLB TLS certificate."
  default     = []
}

variable "nlb_ssl_policy" {
  type        = string
  description = "TLS security policy for the NLB listener."
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}
