# Block Countries
resource "cloudflare_filter" "block_countries" {
  zone_id     = data.cloudflare_zone.domain.id
  description = "Expression to block countries"
  expression  = "(ip.geoip.country in {\"CN\" \"IN\" \"KP\" \"RU\"})"
}
resource "cloudflare_firewall_rule" "block_countries" {
  zone_id     = data.cloudflare_zone.domain.id
  description = "Firewall rule to block countries"
  filter_id   = cloudflare_filter.block_countries.id
  action      = "block"
}

# Block Bots
resource "cloudflare_filter" "bots" {
  zone_id     = data.cloudflare_zone.domain.id
  description = "Expression to block bots determined by CF"
  expression  = "(cf.client.bot) or (cf.threat_score gt 14)"
}
resource "cloudflare_firewall_rule" "bots" {
  zone_id     = data.cloudflare_zone.domain.id
  description = "Firewall rule to block bots determined by CF"
  filter_id   = cloudflare_filter.bots.id
  action      = "block"
}

# Block Plex notifications (prevents cloudflared container spam)
resource "cloudflare_filter" "plex_notifications" {
  zone_id     = data.cloudflare_zone.domain.id
  description = "Expression to block Plex notifications"
  expression  = "(http.host eq \"plex.devbu.io\" and http.request.uri.path contains \"/:/eventsource/notifications\")"
}
resource "cloudflare_firewall_rule" "plex_notifications" {
  zone_id     = data.cloudflare_zone.domain.id
  description = "Firewall rule to block Plex notifications"
  filter_id   = cloudflare_filter.plex_notifications.id
  action      = "block"
}

# Accept Flux Github Webhook
resource "cloudflare_filter" "domain_github_flux_webhook" {
  zone_id     = data.cloudflare_zone.domain.id
  description = "Allow GitHub flux API"
  expression  = "(http.host eq \"flux-webhook.devbu.io\" and ip.geoip.asnum eq 36459)"
}
resource "cloudflare_firewall_rule" "domain_github_flux_webhook" {
  zone_id     = data.cloudflare_zone.domain.id
  description = "Allow GitHub flux API"
  filter_id   = cloudflare_filter.domain_github_flux_webhook.id
  action      = "allow"
}

# Accept UptimeRobot Addresses
data "http" "uptimerobot_ips" {
  url = "https://uptimerobot.com/inc/files/ips/IPv4.txt"
}
resource "cloudflare_list" "uptimerobot" {
  account_id  = cloudflare_account.main.id
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
  zone_id     = data.cloudflare_zone.domain.id
  description = "Expression to allow UptimeRobot IP addresses"
  expression  = "(ip.src in $uptimerobot)"
  depends_on = [
    cloudflare_list.uptimerobot,
  ]
}
resource "cloudflare_firewall_rule" "uptimerobot" {
  zone_id     = data.cloudflare_zone.domain.id
  description = "Firewall rule to allow UptimeRobot IP addresses"
  filter_id   = cloudflare_filter.uptimerobot.id
  action      = "allow"
}
