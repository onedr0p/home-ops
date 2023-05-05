data "http" "ipv4" {
  url = "http://ipv4.icanhazip.com"
}

data "cloudflare_zone" "public_domain" {
  name = "devbu.io"
}

resource "cloudflare_record" "public_domain_apex" {
  name    = "ipv4"
  zone_id = data.cloudflare_zone.public_domain.id
  value   = chomp(data.http.ipv4.response_body)
  proxied = true
  type    = "A"
  ttl     = 1
}

resource "cloudflare_record" "public_domain_root" {
  name    = "devbu.io"
  zone_id = data.cloudflare_zone.public_domain.id
  value   = "ipv4.devbu.io"
  proxied = true
  type    = "CNAME"
  ttl     = 1
}

resource "cloudflare_record" "public_domain_public_cname" {
  name    = data.sops_file.secrets.data["cloudflare_unproxied_cname"]
  zone_id = data.cloudflare_zone.public_domain.id
  value   = "ipv4.devbu.io"
  proxied = false
  type    = "CNAME"
  ttl     = 1
}

resource "cloudflare_record" "public_domain_uptimerobot" {
  name    = "status"
  zone_id = data.cloudflare_zone.public_domain.id
  value   = "stats.uptimerobot.com"
  proxied = false
  type    = "CNAME"
  ttl     = 1
}

resource "cloudflare_zone_settings_override" "public_domain_settings" {
  zone_id = data.cloudflare_zone.public_domain.id
  settings {
    ssl                      = "strict"
    always_use_https         = "on"
    min_tls_version          = "1.2"
    opportunistic_encryption = "on"
    tls_1_3                  = "zrt"
    automatic_https_rewrites = "on"
    universal_ssl            = "on"
    browser_check            = "on"
    challenge_ttl            = 1800
    privacy_pass             = "on"
    security_level           = "medium"
    brotli                   = "on"
    minify {
      css  = "on"
      js   = "on"
      html = "on"
    }
    rocket_loader       = "off"
    always_online       = "off"
    development_mode    = "off"
    http3               = "on"
    zero_rtt            = "on"
    ipv6                = "on"
    websockets          = "on"
    opportunistic_onion = "on"
    pseudo_ipv4         = "off"
    ip_geolocation      = "on"
    email_obfuscation   = "on"
    server_side_exclude = "on"
    hotlink_protection  = "off"
    security_header {
      enabled = false
    }
  }
}

resource "cloudflare_filter" "public_domain_github_flux_webhook" {
  zone_id     = data.cloudflare_zone.public_domain.id
  description = "Allow GitHub flux API"
  expression  = "(ip.geoip.asnum eq 36459 and http.host eq \"flux-webhook.devbu.io\")"
}

resource "cloudflare_firewall_rule" "public_domain_github_flux_webhook" {
  zone_id     = data.cloudflare_zone.public_domain.id
  description = "Allow GitHub flux API"
  filter_id   = cloudflare_filter.public_domain_github_flux_webhook.id
  action      = "allow"
  priority    = 1
}

#
# GeoIP blocking
#

resource "cloudflare_filter" "countries" {
  zone_id     = data.cloudflare_zone.public_domain.id
  description = "Expression to block all countries except US, CA, PH and AU"
  expression  = "(ip.geoip.country ne \"US\" and ip.geoip.country ne \"CA\" and ip.geoip.country ne \"AU\" and ip.geoip.country ne \"PH\")"
}

resource "cloudflare_firewall_rule" "countries" {
  zone_id     = data.cloudflare_zone.public_domain.id
  description = "Firewall rule to block all countries except US, CA, PH, and AU"
  filter_id   = cloudflare_filter.countries.id
  action      = "block"
}

#
# Bots
#

resource "cloudflare_filter" "bots" {
  zone_id     = data.cloudflare_zone.public_domain.id
  description = "Expression to block bots determined by CF"
  expression  = "(cf.client.bot) or (cf.threat_score gt 14)"
}

resource "cloudflare_firewall_rule" "bots" {
  zone_id     = data.cloudflare_zone.public_domain.id
  description = "Firewall rule to block bots determined by CF"
  filter_id   = cloudflare_filter.bots.id
  action      = "block"
}

#
# UptimeRobot
#

data "http" "uptimerobot_ips" {
  url = "https://uptimerobot.com/inc/files/ips/IPv4.txt"
}

resource "cloudflare_list" "uptimerobot" {
  account_id  = data.sops_file.secrets.data["cloudflare_account_id"]
  name        = "uptimerobot"
  kind        = "ip"
  description = "List of UptimeRobot IP Addresses"

  dynamic "item" {
    for_each = split("\r\n", chomp(data.http.uptimerobot_ips.response_body))
    content {
      value {
        ip = item.value
      }
    }
  }
}

resource "cloudflare_filter" "uptimerobot" {
  zone_id     = data.cloudflare_zone.public_domain.id
  description = "Expression to allow UptimeRobot IP addresses"
  expression  = "(ip.src in $uptimerobot)"
  depends_on = [
    cloudflare_list.uptimerobot,
  ]
}

resource "cloudflare_firewall_rule" "uptimerobot" {
  zone_id     = data.cloudflare_zone.public_domain.id
  description = "Firewall rule to allow UptimeRobot IP addresses"
  filter_id   = cloudflare_filter.uptimerobot.id
  action      = "allow"
}
