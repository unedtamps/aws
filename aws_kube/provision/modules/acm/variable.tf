variable "domain_name" {
  type        = string
  description = "Domain name covered by the ACM certificate."
}

variable "cloudflare_zone_id" {
  type        = string
  description = "Cloudflare zone ID for the domain."
}

variable "subject_alternative_names" {
  type        = list(string)
  description = "Additional DNS names covered by the ACM certificate."
  default     = []
}
