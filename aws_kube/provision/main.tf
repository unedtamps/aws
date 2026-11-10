module "networking" {
  cluster_name = var.cluster_name
  source       = "./modules/networking"
}

module "eks" {
  source = "./modules/eks"

  cluster_name                         = var.cluster_name
  cluster_version                      = var.cluster_version
  cluster_endpoint_public_access       = var.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs
  additional_security_group_ids        = [aws_security_group.eks_api_vpn.id]
  private_subnet_ids                   = module.networking.private_subnet_ids
  external_secret_role_arn             = module.secret.external_secrets_role_arn
}
module "acm" {
  source = "./modules/acm"

  domain_name               = var.acm_domain_name
  subject_alternative_names = var.acm_subject_alternative_names
  cloudflare_zone_id        = var.cloudflare_zone_id
}

module "lb" {
  source = "./modules/lb"

  vpc_id            = module.networking.vpc_id
  public_subnet_ids = module.networking.public_subnet_ids

  acm_certificate_arn = module.acm.certificate_arn
  ssl_policy          = var.nlb_ssl_policy
}

module "secret" {
  source       = "./modules/secret"
  cluster_name = var.cluster_name
}
