data "cloudflare_zones" "domain" {
  filter {
    name = data.sops_file.cloudflare_secrets.data["cloudflare_domain"]
  }
}

resource "cloudflare_zone_settings_override" "cloudflare_settings" {
  zone_id = lookup(data.cloudflare_zones.domain.zones[0], "id")
  settings {
    always_online            = "on"
    always_use_https         = "off"
    automatic_https_rewrites = "off"
    brotli                   = "on"
    browser_check            = "on"
    challenge_ttl            = 2700
    development_mode         = "off"
    email_obfuscation        = "on"
    hotlink_protection       = "on"
    ip_geolocation           = "on"
    ipv6                     = "on"
    min_tls_version          = "1.1"
    opportunistic_encryption = "off"
    opportunistic_onion      = "on"
    privacy_pass             = "on"
    rocket_loader            = "on"
    security_level           = "high"
    server_side_exclude      = "on"
    ssl                      = "off"
    tls_1_3                  = "zrt"
    tls_client_auth          = "off"
    universal_ssl            = "off"
    websockets               = "off"
    zero_rtt                 = "off"
    minify {
      css  = "on"
      js   = "on"
      html = "on"
    }
    security_header {
      enabled = false
    }
  }
}

data "http" "ipv4" {
  url = "http://ipv4.icanhazip.com"
}

resource "cloudflare_record" "ipv4" {
  name    = "ipv4"
  zone_id = lookup(data.cloudflare_zones.domain.zones[0], "id")
  value   = chomp(data.http.ipv4.body)
  proxied = true
  type    = "A"
  ttl     = 1
}

resource "cloudflare_record" "root" {
  name    = data.sops_file.cloudflare_secrets.data["cloudflare_domain"]
  zone_id = lookup(data.cloudflare_zones.domain.zones[0], "id")
  value   = "ipv4.${data.sops_file.cloudflare_secrets.data["cloudflare_domain"]}"
  proxied = true
  type    = "CNAME"
  ttl     = 1
}

resource "cloudflare_record" "test" {
  name    = "test"
  zone_id = lookup(data.cloudflare_zones.domain.zones[0], "id")
  value   = "ipv4.${data.sops_file.cloudflare_secrets.data["cloudflare_domain"]}"
  proxied = true
  type    = "CNAME"
  ttl     = 1
}
