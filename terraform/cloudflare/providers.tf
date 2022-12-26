provider "cloudflare" {
  email   = "devin.kray@gmail.com"
  api_key = data.sops_file.secrets.data["cloudflare_apikey"]
}
