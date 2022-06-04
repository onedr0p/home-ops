#
# GeoIP blocking
#

resource "cloudflare_filter" "countries" {
  zone_id     = lookup(data.cloudflare_zones.domain_io.zones[0], "id")
  description = "Expression to block all countries except US, CA, NL and AU"
  expression  = "(ip.geoip.country ne \"US\" and ip.geoip.country ne \"CA\" and ip.geoip.country ne \"NL\" and ip.geoip.country ne \"AU\")"
}

resource "cloudflare_firewall_rule" "countries" {
  zone_id     = lookup(data.cloudflare_zones.domain_io.zones[0], "id")
  description = "Firewall rule to block all countries except US, CA and AU"
  filter_id   = cloudflare_filter.countries.id
  action      = "block"
}

#
# Bots
#

resource "cloudflare_filter" "bots" {
  zone_id     = lookup(data.cloudflare_zones.domain_io.zones[0], "id")
  description = "Expression to block bots determined by CF"
  expression  = "(cf.client.bot)"
}

resource "cloudflare_firewall_rule" "bots" {
  zone_id     = lookup(data.cloudflare_zones.domain_io.zones[0], "id")
  description = "Firewall rule to block bots determined by CF"
  filter_id   = cloudflare_filter.bots.id
  action      = "block"
}

#
# Block threats less than Medium
#

resource "cloudflare_filter" "threats" {
  zone_id     = lookup(data.cloudflare_zones.domain_io.zones[0], "id")
  description = "Expression to block medium threats"
  expression  = "(cf.threat_score gt 14)"
}

resource "cloudflare_firewall_rule" "threats" {
  zone_id     = lookup(data.cloudflare_zones.domain_io.zones[0], "id")
  description = "Firewall rule to block medium threats"
  filter_id   = cloudflare_filter.threats.id
  action      = "block"
}

#
# UptimeRobot
#

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
  zone_id     = lookup(data.cloudflare_zones.domain_io.zones[0], "id")
  description = "Expression to allow UptimeRobot IP addresses"
  expression  = "(ip.src in $uptimerobot)"
  depends_on = [
    cloudflare_ip_list.uptimerobot,
  ]
}

resource "cloudflare_firewall_rule" "uptimerobot" {
  zone_id     = lookup(data.cloudflare_zones.domain_io.zones[0], "id")
  description = "Firewall rule to allow UptimeRobot IP addresses"
  filter_id   = cloudflare_filter.uptimerobot.id
  action      = "allow"
}
