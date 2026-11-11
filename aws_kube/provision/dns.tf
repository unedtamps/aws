resource "cloudflare_dns_record" "traefik" {
  zone_id = var.cloudflare_zone_id
  name    = "traefik.lensboxd.site"
  type    = "CNAME"
  content = module.lb.nlb_dns_name

  ttl     = 1
  proxied = false
}
resource "cloudflare_dns_record" "ontime" {
  zone_id = var.cloudflare_zone_id
  name    = "ontime.lensboxd.site"
  type    = "CNAME"
  content = module.lb.nlb_dns_name

  ttl     = 1
  proxied = false
}

resource "cloudflare_dns_record" "ticketbus" {
  zone_id = var.cloudflare_zone_id
  name    = "ticketbus.lensboxd.site"
  type    = "CNAME"
  content = module.lb.nlb_dns_name

  ttl     = 1
  proxied = false
}
