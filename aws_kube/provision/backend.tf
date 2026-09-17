terraform {
  backend "s3" {
    bucket       = "aws-kube-tofu-state-246830848520"
    key          = "aws-kube/dev/eks/terraform.tfstate"
    region       = "eu-north-1"
    encrypt      = true
    use_lockfile = true
  }
}
