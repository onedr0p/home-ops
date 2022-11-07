terraform {

  required_version = ">= 1.3.0"
  cloud {
    hostname = "app.terraform.io"
    organization = "onedr0p"

    workspaces {
      name = "home-cloudflare"
    }
  }

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "3.27.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.2.1"
    }
  }
}

# Obtain current home IP address
data "http" "ipv4" {
  url = "http://ipv4.icanhazip.com"
}

data "cloudflare_zones" "domain_io" {
  filter {
    name = var.cloudflare_domain_io
  }
}

data "cloudflare_zones" "domain_ac" {
  filter {
    name = var.cloudflare_domain_ac
  }
}

data "cloudflare_zones" "domain_casa" {
  filter {
    name = var.cloudflare_domain_casa
  }
}
