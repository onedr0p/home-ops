resource "cloudflare_page_rule" "plex_bypass_cache" {
  zone_id  = lookup(data.cloudflare_zones.domain_io.zones[0], "id")
  target   = "plex.${var.cloudflare_domain_io}/*"
  status   = "active"
  priority = 1

  actions {
    cache_level = "bypass"
  }
}

resource "cloudflare_page_rule" "hass_bypass_cache" {
  zone_id  = lookup(data.cloudflare_zones.domain_io.zones[0], "id")
  target   = "hass.${var.cloudflare_domain_io}/*"
  status   = "active"
  priority = 2

  actions {
    cache_level = "bypass"
  }
}
