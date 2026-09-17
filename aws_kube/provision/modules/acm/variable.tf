variable "domain_name" {
  type        = string
  description = "Domain name covered by the ACM certificate."
}

variable "cloudflare_zone_id" {
  type        = string
  description = "Cloudflare zone ID for the domain."
}
