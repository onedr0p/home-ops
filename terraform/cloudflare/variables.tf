# Provider
variable "cloudflare_apikey" {
  description = "cloudflare api key (not token)"
  type        = string
}
# Domains
variable "cloudflare_unproxied_cname" {
  description = "cloudflare unproxied cname"
  type        = string
}
