variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "eu-north-1"
}

variable "instance_ami_id" {
  type        = string
  description = "AMI used by the application instances"
  default     = "ami-0b79f6b294a030f24"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t3.micro"
}

variable "key_name" {
  type        = string
  description = "EC2 key pair name"
  default     = "ec-keypair"
}

variable "iam_instance_profile" {
  type        = string
  description = "IAM instance profile attached to the EC2 instances"
  default     = "instanceRole"
}
