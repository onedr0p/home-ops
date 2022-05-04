#
# Mailgun
#

resource "cloudflare_record" "cname_mailgun" {
  name    = "email.mg"
  zone_id = lookup(data.cloudflare_zones.domain_casa.zones[0], "id")
  value   = "mailgun.org"
  proxied = false
  type    = "CNAME"
  ttl     = 1
}

resource "cloudflare_record" "mx_mailgun_a" {
  name    = "mg"
  zone_id = lookup(data.cloudflare_zones.domain_casa.zones[0], "id")
  value   = "mxa.mailgun.org"
  proxied = false
  type    = "MX"
  ttl     = 1
  priority = 10
}

resource "cloudflare_record" "mx_mailgun_b" {
  name    = "mg"
  zone_id = lookup(data.cloudflare_zones.domain_casa.zones[0], "id")
  value   = "mxb.mailgun.org"
  proxied = false
  type    = "MX"
  ttl     = 1
  priority = 10
}

resource "cloudflare_record" "txt_mailgun_spf" {
  name    = "mg"
  zone_id = lookup(data.cloudflare_zones.domain_casa.zones[0], "id")
  value   = "v=spf1 include:mailgun.org ~all"
  proxied = false
  type    = "TXT"
  ttl     = 1
}

resource "cloudflare_record" "txt_mailgun_cert" {
  name    = "krs._domainkey.mg"
  zone_id = lookup(data.cloudflare_zones.domain_casa.zones[0], "id")
  value   = data.sops_file.cloudflare_secrets.data["mailgun_cert"]
  proxied = false
  type    = "TXT"
  ttl     = 1
}

#
# Fastmail
#

resource "cloudflare_record" "cname_fastmail_1" {
  name    = "fm1._domainkey"
  zone_id = lookup(data.cloudflare_zones.domain_casa.zones[0], "id")
  value   = "fm1.${data.sops_file.cloudflare_secrets.data["cloudflare_domain_casa"]}.dkim.fmhosted.com"
  proxied = false
  type    = "CNAME"
  ttl     = 1
}

resource "cloudflare_record" "cname_fastmail_2" {
  name    = "fm2._domainkey"
  zone_id = lookup(data.cloudflare_zones.domain_casa.zones[0], "id")
  value   = "fm2.${data.sops_file.cloudflare_secrets.data["cloudflare_domain_casa"]}.dkim.fmhosted.com"
  proxied = false
  type    = "CNAME"
  ttl     = 1
}

resource "cloudflare_record" "cname_fastmail_3" {
  name    = "fm3._domainkey"
  zone_id = lookup(data.cloudflare_zones.domain_casa.zones[0], "id")
  value   = "fm3.${data.sops_file.cloudflare_secrets.data["cloudflare_domain_casa"]}.dkim.fmhosted.com"
  proxied = false
  type    = "CNAME"
  ttl     = 1
}

resource "cloudflare_record" "mx_fastmail_1" {
  name    = data.sops_file.cloudflare_secrets.data["cloudflare_domain_casa"]
  zone_id = lookup(data.cloudflare_zones.domain_casa.zones[0], "id")
  value   = "in1-smtp.messagingengine.com"
  proxied = false
  type    = "MX"
  ttl     = 1
  priority = 10
}

resource "cloudflare_record" "mx_fastmail_2" {
  name    = data.sops_file.cloudflare_secrets.data["cloudflare_domain_casa"]
  zone_id = lookup(data.cloudflare_zones.domain_casa.zones[0], "id")
  value   = "in2-smtp.messagingengine.com"
  proxied = false
  type    = "MX"
  ttl     = 1
  priority = 20
}

resource "cloudflare_record" "txt_fastmail_spf" {
  name    = data.sops_file.cloudflare_secrets.data["cloudflare_domain_casa"]
  zone_id = lookup(data.cloudflare_zones.domain_casa.zones[0], "id")
  value   = "v=spf1 include:spf.messagingengine.com ?all"
  proxied = false
  type    = "TXT"
  ttl     = 1
}

#
# Additional email records
#

resource "cloudflare_record" "txt_dmarc" {
  name    = "_dmarc"
  zone_id = lookup(data.cloudflare_zones.domain_casa.zones[0], "id")
  value   = "v=DMARC1; p=none; rua=mailto:${data.sops_file.cloudflare_secrets.data["cloudflare_email"]}"
  proxied = false
  type    = "TXT"
  ttl     = 1
}
