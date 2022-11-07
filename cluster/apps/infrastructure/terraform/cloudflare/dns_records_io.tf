#
# Base records
#

# Record which will be updated by DDNS
resource "cloudflare_record" "apex_ipv4" {
  name    = "ipv4"
  zone_id = lookup(data.cloudflare_zones.domain_io.zones[0], "id")
  value   = chomp(data.http.ipv4.response_body)
  proxied = true
  type    = "A"
  ttl     = 1
}

resource "cloudflare_record" "cname_root" {
  name    = var.cloudflare_domain_io
  zone_id = lookup(data.cloudflare_zones.domain_io.zones[0], "id")
  value   = "ipv4.${var.cloudflare_domain_io}"
  proxied = true
  type    = "CNAME"
  ttl     = 1
}

resource "cloudflare_record" "cname_www" {
  name    = "www"
  zone_id = lookup(data.cloudflare_zones.domain_io.zones[0], "id")
  value   = "ipv4.${var.cloudflare_domain_io}"
  proxied = true
  type    = "CNAME"
  ttl     = 1
}
resource "cloudflare_record" "cname_public" {
  name    = "${var.cloudflare_public_cname_domain_io}"
  zone_id = lookup(data.cloudflare_zones.domain_io.zones[0], "id")
  value   = "ipv4.${var.cloudflare_domain_io}"
  proxied = false
  type    = "CNAME"
  ttl     = 1
}

#
# UptimeRobot
#

resource "cloudflare_record" "cname_uptimerobot" {
  name    = "status"
  zone_id = lookup(data.cloudflare_zones.domain_io.zones[0], "id")
  value   = "stats.uptimerobot.com"
  proxied = false
  type    = "CNAME"
  ttl     = 1
}
