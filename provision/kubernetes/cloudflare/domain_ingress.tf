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
