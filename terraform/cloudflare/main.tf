terraform {
  cloud {
    hostname     = "app.terraform.io"
    organization = "onedr0p"
    workspaces {
      name = "arpa-home-cloudflare"
    }
  }
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "3.30.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.2.1"
    }
  }
  required_version = ">= 1.3.0"
}

provider "cloudflare" {
  email   = "devin.kray@gmail.com"
  api_key = var.cloudflare_apikey
}
