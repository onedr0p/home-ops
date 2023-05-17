resource "cloudflare_page_rule" "bypass_cache_plex" {
  zone_id  = data.cloudflare_zone.domain.id
  target   = format("plex.%s/*", data.cloudflare_zone.domain.name)
  status   = "active"
  priority = 1

  actions {
    cache_level         = "bypass"
    disable_performance = true
  }
}
