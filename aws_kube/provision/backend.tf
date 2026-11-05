terraform {
  backend "s3" {
    bucket = "aws-kube-tofu-state-246830848520"
    key    = "aws-kube/dev/eks/terraform.tfstate"
    # The state bucket lives in eu-north-1 and is accessed cross-region;
    # keep this value even though the lab resources run in ap-southeast-1.
    region       = "eu-north-1"
    encrypt      = true
    use_lockfile = true
  }
}
