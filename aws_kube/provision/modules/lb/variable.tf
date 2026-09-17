
variable "vpc_id" {
  type        = string
  description = "VPC ID where the NLB and target group are created."
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "Public subnet IDs used by the internet-facing NLB."

  validation {
    condition     = length(var.public_subnet_ids) >= 2
    error_message = "At least two public subnets are required."
  }
}

variable "acm_certificate_arn" {
  type        = string
  description = "Issued ACM certificate ARN for the NLB TLS listener."
}
variable "ssl_policy" {
  type        = string
  description = "TLS security policy for the NLB listener."
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

