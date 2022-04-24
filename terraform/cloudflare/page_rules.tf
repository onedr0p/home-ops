resource "cloudflare_page_rule" "plex_bypass_cache" {
  zone_id = lookup(data.cloudflare_zones.domain.zones[0], "id")
  target  = "plex.${data.sops_file.cloudflare_secrets.data["cloudflare_domain"]}/*"
  status  = "active"

  actions {
    cache_level = "bypass"
  }
}
