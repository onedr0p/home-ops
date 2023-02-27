provider "cloudflare" {
  email   = data.sops_file.secrets.data["cloudflare_email"]
  api_key = data.sops_file.secrets.data["cloudflare_apikey"]
}
