terraform {

  backend "remote" {
    organization = "onedr0p"
    workspaces {
      name = "home-cloudflare"
    }
  }

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "3.14.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "2.1.0"
    }
    sops = {
      source  = "carlpett/sops"
      version = "0.7.0"
    }
  }
}

data "sops_file" "cloudflare_secrets" {
  source_file = "secret.sops.yaml"
}

provider "cloudflare" {
  email   = data.sops_file.cloudflare_secrets.data["cloudflare_email"]
  api_key = data.sops_file.cloudflare_secrets.data["cloudflare_apikey"]
}

data "cloudflare_zones" "domain_io" {
  filter {
    name = data.sops_file.cloudflare_secrets.data["cloudflare_domain_io"]
  }
}

data "cloudflare_zones" "domain_ac" {
  filter {
    name = data.sops_file.cloudflare_secrets.data["cloudflare_domain_ac"]
  }
}

data "cloudflare_zones" "domain_casa" {
  filter {
    name = data.sops_file.cloudflare_secrets.data["cloudflare_domain_casa"]
  }
}
