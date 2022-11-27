# Provider
variable "cloudflare_email" {
  description = "cloudflare email address"
  type        = string
}
variable "cloudflare_apikey" {
  description = "cloudflare api key (not token)"
  type        = string
}
# Domains
variable "cloudflare_domain_public_name" {
  description = "cloudflare public domain name"
  type        = string
}
variable "cloudflare_domain_public_unproxied_cname" {
  description = "cloudflare public domain unproxied cname"
  type        = string
}
variable "cloudflare_domain_email_name" {
  description = "cloudflare email domain name"
  type        = string
}
