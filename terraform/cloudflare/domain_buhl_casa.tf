data "cloudflare_zones" "email_domain" {
  filter {
    name = "buhl.casa"
  }
}

resource "cloudflare_record" "email_domain_fastmail_cname1" {
  name    = "fm1._domainkey"
  zone_id = lookup(data.cloudflare_zones.email_domain.zones[0], "id")
  value   = "fm1.buhl.casa.dkim.fmhosted.com"
  proxied = false
  type    = "CNAME"
  ttl     = 1
}

resource "cloudflare_record" "email_domain_fastmail_cname2" {
  name    = "fm2._domainkey"
  zone_id = lookup(data.cloudflare_zones.email_domain.zones[0], "id")
  value   = "fm2.buhl.casa.dkim.fmhosted.com"
  proxied = false
  type    = "CNAME"
  ttl     = 1
}

resource "cloudflare_record" "email_domain_fastmail_cname3" {
  name    = "fm3._domainkey"
  zone_id = lookup(data.cloudflare_zones.email_domain.zones[0], "id")
  value   = "fm3.buhl.casa.dkim.fmhosted.com"
  proxied = false
  type    = "CNAME"
  ttl     = 1
}

resource "cloudflare_record" "email_domain_fastmail_mx1" {
  name     = "buhl.casa"
  zone_id  = lookup(data.cloudflare_zones.email_domain.zones[0], "id")
  value    = "in1-smtp.messagingengine.com"
  proxied  = false
  type     = "MX"
  ttl      = 1
  priority = 10
}

resource "cloudflare_record" "email_domain_fastmail_mx2" {
  name     = "buhl.casa"
  zone_id  = lookup(data.cloudflare_zones.email_domain.zones[0], "id")
  value    = "in2-smtp.messagingengine.com"
  proxied  = false
  type     = "MX"
  ttl      = 1
  priority = 20
}

resource "cloudflare_record" "email_domain_fastmail_spf" {
  name    = "buhl.casa"
  zone_id = lookup(data.cloudflare_zones.email_domain.zones[0], "id")
  value   = "v=spf1 include:spf.messagingengine.com ?all"
  proxied = false
  type    = "TXT"
  ttl     = 1
}

resource "cloudflare_record" "email_domain_fastmail_dmarc" {
  name    = "_dmarc"
  zone_id = lookup(data.cloudflare_zones.email_domain.zones[0], "id")
  value   = "v=DMARC1; p=none; rua=mailto:${data.sops_file.secrets.data["cloudflare_email"]}"
  proxied = false
  type    = "TXT"
  ttl     = 1
}
