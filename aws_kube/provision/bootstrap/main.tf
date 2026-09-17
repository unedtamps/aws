# This bootstrap stack intentionally uses local state because it creates the
# S3 bucket that the main EKS stack will use as its remote backend.
terraform {
  required_version = ">= 1.8.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.63.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type        = string
  description = "AWS region for the state bucket."
  default     = "eu-north-1"
}

variable "state_bucket_name" {
  type        = string
  description = "Globally unique S3 bucket name for OpenTofu state."
  default     = "aws-kube-tofu-state-246830848520"
}

variable "state_key" {
  type        = string
  description = "Object key used by the EKS stack for its remote state."
  default     = "aws-kube/dev/eks/terraform.tfstate"
}

locals {
  tags = {
    Name      = var.state_bucket_name
    Project   = "aws-kube-lab"
    ManagedBy = "OpenTofu"
    Purpose   = "OpenTofu remote state"
  }
}

resource "aws_s3_bucket" "state" {
  bucket        = var.state_bucket_name
  force_destroy = false

  tags = local.tags
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

data "aws_iam_policy_document" "deny_insecure_transport" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.state.arn,
      "${aws_s3_bucket.state.arn}/*",
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "state" {
  bucket = aws_s3_bucket.state.id
  policy = data.aws_iam_policy_document.deny_insecure_transport.json
}

output "state_bucket_name" {
  description = "S3 bucket name for the shared OpenTofu state."
  value       = aws_s3_bucket.state.bucket
}

output "state_key" {
  description = "Remote state object key for the EKS stack."
  value       = var.state_key
}
