terraform {

  backend "remote" {
    organization = "onedr0p"
    workspaces {
      name = "home-cloudflare-casa-tld"
    }
  }

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "3.13.0"
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

data "cloudflare_zones" "domain_1" {
  filter {
    name = data.sops_file.cloudflare_secrets.data["cloudflare_domain_1"]
  }
}

data "cloudflare_zones" "domain_2" {
  filter {
    name = data.sops_file.cloudflare_secrets.data["cloudflare_domain_2"]
  }
}

data "cloudflare_zones" "domain_3" {
  filter {
    name = data.sops_file.cloudflare_secrets.data["cloudflare_domain_3"]
  }
}
