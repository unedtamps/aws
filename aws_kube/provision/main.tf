module "networking" {
  cluster_name = var.cluster_name
  source       = "./modules/networking"
}

module "iam" {
  source = "./modules/iam"
}

module "eks" {
  source = "./modules/eks"

  cluster_name                         = var.cluster_name
  cluster_version                      = var.cluster_version
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs
  private_subnet_ids                   = module.networking.private_subnet_ids
  cluster_role_arn                     = module.iam.cluster_role_arn
  node_role_arn                        = module.iam.node_role_arn
  vpc_cni_role_arn                     = module.iam.vpc_cni_role_arn

  # EKS resources must wait for the IAM roles and policy attachments.
  depends_on = [module.iam]
}
module "acm" {
  source = "./modules/acm"

  domain_name        = var.acm_domain_name
  cloudflare_zone_id = var.cloudflare_zone_id
}

module "lb" {
  source = "./modules/lb"

  vpc_id            = module.networking.vpc_id
  public_subnet_ids = module.networking.public_subnet_ids

  acm_certificate_arn = module.acm.certificate_arn
  ssl_policy          = var.nlb_ssl_policy
}
