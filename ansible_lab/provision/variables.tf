variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "eu-north-1"
}
variable "instance_count" {
  default = 3

}
variable "instance_names" {
  type    = list(string)
  default = ["ec2-ans-0", "ec2-ans-1", "ec2-ans-2"]
}

variable "instance_ami_id" {
  type        = string
  description = "AMI used by the application instances"
  default     = "ami-09d835910a77f135c"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t3.micro"
}

variable "key_name" {
  type        = string
  description = "EC2 key pair name"
  default     = "ansible-key"
}

variable "iam_instance_profile" {
  type        = string
  description = "IAM instance profile attached to the EC2 instances"
  default     = "instanceRole"
}
