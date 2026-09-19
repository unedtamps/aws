variable "cluster_name" {
  type        = string
  description = "EKS cluster name."
}

variable "secret_name" {
  type        = string
  description = "Logical name of the secret."
  default     = "external-secrets/app"
}
