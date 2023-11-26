provider "cloudflare" {
  email   = module.onepassword_item.fields["CLOUDFLARE_EMAIL"]
  api_key = module.onepassword_item.fields["CLOUDFLARE_API_KEY"]
}
