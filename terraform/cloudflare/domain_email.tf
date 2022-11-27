data "cloudflare_zones" "email_domain" {
  filter {
    name = var.cloudflare_domain_email_name
  }
}

# resource "cloudflare_record" "email_domain_mailgun_cname" {
#   name    = "email.mg"
#   zone_id = lookup(data.cloudflare_zones.email_domain.zones[0], "id")
#   value   = "mailgun.org"
#   proxied = false
#   type    = "CNAME"
#   ttl     = 1
# }

# resource "cloudflare_record" "email_domain_mailgun_mxa" {
#   name     = "mg"
#   zone_id  = lookup(data.cloudflare_zones.email_domain.zones[0], "id")
#   value    = "mxa.mailgun.org"
#   proxied  = false
#   type     = "MX"
#   ttl      = 1
#   priority = 10
# }

# resource "cloudflare_record" "email_domain_mailgun_mxb" {
#   name     = "mg"
#   zone_id  = lookup(data.cloudflare_zones.email_domain.zones[0], "id")
#   value    = "mxb.mailgun.org"
#   proxied  = false
#   type     = "MX"
#   ttl      = 1
#   priority = 10
# }

# resource "cloudflare_record" "email_domain_mailgun_spf" {
#   name    = "mg"
#   zone_id = lookup(data.cloudflare_zones.email_domain.zones[0], "id")
#   value   = "v=spf1 include:mailgun.org ~all"
#   proxied = false
#   type    = "TXT"
#   ttl     = 1
# }

# resource "cloudflare_record" "email_domain_mailgun_certificate" {
#   name    = "krs._domainkey.mg"
#   zone_id = lookup(data.cloudflare_zones.email_domain.zones[0], "id")
#   value   = var.cloudflare_domain_email_mailgun_certificate
#   proxied = false
#   type    = "TXT"
#   ttl     = 1
# }

resource "cloudflare_record" "email_domain_fastmail_cname1" {
  name    = "fm1._domainkey"
  zone_id = lookup(data.cloudflare_zones.email_domain.zones[0], "id")
  value   = "fm1.${var.cloudflare_domain_email_name}.dkim.fmhosted.com"
  proxied = false
  type    = "CNAME"
  ttl     = 1
}

resource "cloudflare_record" "email_domain_fastmail_cname2" {
  name    = "fm2._domainkey"
  zone_id = lookup(data.cloudflare_zones.email_domain.zones[0], "id")
  value   = "fm2.${var.cloudflare_domain_email_name}.dkim.fmhosted.com"
  proxied = false
  type    = "CNAME"
  ttl     = 1
}

resource "cloudflare_record" "email_domain_fastmail_cname3" {
  name    = "fm3._domainkey"
  zone_id = lookup(data.cloudflare_zones.email_domain.zones[0], "id")
  value   = "fm3.${var.cloudflare_domain_email_name}.dkim.fmhosted.com"
  proxied = false
  type    = "CNAME"
  ttl     = 1
}

resource "cloudflare_record" "email_domain_fastmail_mx1" {
  name     = var.cloudflare_domain_email_name
  zone_id  = lookup(data.cloudflare_zones.email_domain.zones[0], "id")
  value    = "in1-smtp.messagingengine.com"
  proxied  = false
  type     = "MX"
  ttl      = 1
  priority = 10
}

resource "cloudflare_record" "email_domain_fastmail_mx2" {
  name     = var.cloudflare_domain_email_name
  zone_id  = lookup(data.cloudflare_zones.email_domain.zones[0], "id")
  value    = "in2-smtp.messagingengine.com"
  proxied  = false
  type     = "MX"
  ttl      = 1
  priority = 20
}

resource "cloudflare_record" "email_domain_fastmail_spf" {
  name    = var.cloudflare_domain_email_name
  zone_id = lookup(data.cloudflare_zones.email_domain.zones[0], "id")
  value   = "v=spf1 include:spf.messagingengine.com ?all"
  proxied = false
  type    = "TXT"
  ttl     = 1
}

resource "cloudflare_record" "email_domain_fastmail_dmarc" {
  name    = "_dmarc"
  zone_id = lookup(data.cloudflare_zones.email_domain.zones[0], "id")
  value   = "v=DMARC1; p=none; rua=mailto:${var.cloudflare_email}"
  proxied = false
  type    = "TXT"
  ttl     = 1
}

# resource "cloudflare_zone_settings_override" "email_domain_settings" {
#   zone_id = lookup(data.cloudflare_zones.email_domain.zones[0], "id")
#   settings {
#     ssl                      = "strict"
#     always_use_https         = "on"
#     min_tls_version          = "1.2"
#     opportunistic_encryption = "on"
#     tls_1_3                  = "zrt"
#     automatic_https_rewrites = "on"
#     universal_ssl            = "on"
#     browser_check            = "on"
#     challenge_ttl            = 1800
#     privacy_pass             = "on"
#     security_level           = "medium"
#     brotli                   = "on"
#     minify {
#       css  = "on"
#       js   = "on"
#       html = "on"
#     }
#     rocket_loader       = "off"
#     always_online       = "off"
#     development_mode    = "off"
#     http3               = "on"
#     zero_rtt            = "on"
#     ipv6                = "on"
#     websockets          = "on"
#     opportunistic_onion = "on"
#     pseudo_ipv4         = "off"
#     ip_geolocation      = "on"
#     email_obfuscation   = "on"
#     server_side_exclude = "on"
#     hotlink_protection  = "off"
#     security_header {
#       enabled = false
#     }
#   }
# }
