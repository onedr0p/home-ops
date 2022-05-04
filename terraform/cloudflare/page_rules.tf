resource "cloudflare_page_rule" "plex_bypass_cache" {
  zone_id = lookup(data.cloudflare_zones.domain_1.zones[0], "id")
  target  = "plex.${data.sops_file.cloudflare_secrets.data["cloudflare_domain_1"]}/*"
  status  = "active"

  actions {
    cache_level = "bypass"
  }
}
