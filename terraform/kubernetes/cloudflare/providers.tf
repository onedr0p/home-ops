provider "cloudflare" {
  email   = module.onepassword_item.fields["email"]
  api_key = module.onepassword_item.fields["api-key"]
}
