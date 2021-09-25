terraform {

  backend "remote" {
    organization = "onedr0p"
    workspaces {
      name = "home-cluster-cloudflare"
    }
  }

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "3.1.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "2.1.0"
    }
    sops = {
      source  = "carlpett/sops"
      version = "0.6.3"
    }
  }
}

data "sops_file" "cloudflare_secrets" {
  source_file = "secret.sops.yaml"
}

provider "cloudflare" {
  email   = data.sops_file.cloudflare_secrets.data["cloudflare_email"]
  api_key = data.sops_file.cloudflare_secrets.data["cloudflare_apikey"]
}

data "cloudflare_zones" "domain" {
  filter {
    name = data.sops_file.cloudflare_secrets.data["cloudflare_domain"]
  }
}

resource "cloudflare_zone_settings_override" "cloudflare_settings" {
  zone_id = lookup(data.cloudflare_zones.domain.zones[0], "id")
  settings {
    # /ssl-tls
    ssl = "strict"
    # /ssl-tls/edge-certificates
    always_use_https         = "on"
    min_tls_version          = "1.0"
    opportunistic_encryption = "on"
    tls_1_3                  = "zrt"
    automatic_https_rewrites = "on"
    universal_ssl            = "on"
    # /firewall/settings
    browser_check  = "on"
    challenge_ttl  = 1800
    privacy_pass   = "on"
    security_level = "medium"
    # /speed/optimization
    brotli = "on"
    minify {
      css  = "on"
      js   = "on"
      html = "on"
    }
    rocket_loader = "on"
    # /caching/configuration
    always_online    = "off"
    development_mode = "off"
    # /network
    http3               = "on"
    zero_rtt            = "on"
    ipv6                = "on"
    websockets          = "on"
    opportunistic_onion = "on"
    pseudo_ipv4         = "off"
    ip_geolocation      = "on"
    # /content-protection
    email_obfuscation   = "on"
    server_side_exclude = "on"
    hotlink_protection  = "off"
    # /workers
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

resource "cloudflare_record" "wireguard" {
  name    = "wg"
  zone_id = lookup(data.cloudflare_zones.domain.zones[0], "id")
  value   = "ipv4.${data.sops_file.cloudflare_secrets.data["cloudflare_domain"]}"
  proxied = false
  type    = "CNAME"
  ttl     = 1
}

resource "cloudflare_record" "uptimerobot" {
  name    = "status"
  zone_id = lookup(data.cloudflare_zones.domain.zones[0], "id")
  value   = "stats.uptimerobot.com"
  proxied = false
  type    = "CNAME"
  ttl     = 1
}

data "http" "uptimerobot_ips" {
  url = "https://uptimerobot.com/inc/files/ips/IPv4.txt"
}

resource "cloudflare_ip_list" "uptimerobot" {
  account_id  = data.sops_file.cloudflare_secrets.data["cloudflare_account_id"]
  name        = "uptimerobot"
  kind        = "ip"
  description = "List of UptimeRobot IP Addresses"

  dynamic "item" {
    for_each = split("\r\n", chomp(data.http.uptimerobot_ips.body))
    content {
      value = item.value
    }
  }
}

resource "cloudflare_filter" "uptimerobot" {
  zone_id     = lookup(data.cloudflare_zones.domain.zones[0], "id")
  description = "Expression to allow UptimeRobot IP addresses"
  expression  = "(ip.src in $uptimerobot)"
  depends_on = [
    cloudflare_ip_list.uptimerobot,
  ]
}

resource "cloudflare_firewall_rule" "uptimerobot" {
  zone_id     = lookup(data.cloudflare_zones.domain.zones[0], "id")
  description = "Firewall rule to allow UptimeRobot IP addresses"
  filter_id   = cloudflare_filter.uptimerobot.id
  action      = "allow"
}

resource "cloudflare_filter" "countries" {
  zone_id     = lookup(data.cloudflare_zones.domain.zones[0], "id")
  description = "Expression to block all countries except US, CA and AU"
  expression  = "(ip.geoip.country ne \"US\" and ip.geoip.country ne \"CA\" and ip.geoip.country ne \"AU\")"
}

resource "cloudflare_firewall_rule" "countries" {
  zone_id     = lookup(data.cloudflare_zones.domain.zones[0], "id")
  description = "Firewall rule to block all countries except US, CA and AU"
  filter_id   = cloudflare_filter.countries.id
  action      = "block"
}

resource "cloudflare_page_rule" "plex_bypass_cache" {
  zone_id = lookup(data.cloudflare_zones.domain.zones[0], "id")
  target  = "test.${data.sops_file.cloudflare_secrets.data["cloudflare_domain"]}/*"
  status  = "active"

  actions {
    cache_level = "bypass"
  }
}
