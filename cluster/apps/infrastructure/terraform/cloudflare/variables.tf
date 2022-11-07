variable "cloudflare_account_id" {
    type = string
    description = "Cloudflare Account ID"
}
variable "cloudflare_email" {
    type = string
    description = "Cloudflare Email Address"
}
variable "cloudflare_apikey" {
    type = string
    description = "Cloudflare Account API Key"
}
variable "cloudflare_domain_io" {
    type = string
    description = "My .io domain"
}
variable "cloudflare_domain_ac" {
    type = string
    description = "My .ac domain"
}
variable "cloudflare_domain_casa" {
    type = string
    description = "My .casa domain"
}
variable "mailgun_cert" {
    type = string
    description = "Mailgun Certificate"
}
variable "cloudflare_public_cname_domain_io" {
    type = string
    description = "Public CNAME that do not proxy thru Cloudflare"
}
