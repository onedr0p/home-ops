terraform {
  cloud {
    hostname     = "app.terraform.io"
    organization = "onedr0p"
    workspaces {
      name = "arpa-home-minio"
    }
  }
  required_providers {
    minio = {
      source  = "aminueza/minio"
      version = "1.10.0"
    }
    sops = {
      source  = "carlpett/sops"
      version = "0.7.1"
    }
  }
  required_version = ">= 1.3.0"
}

data "sops_file" "secrets" {
  source_file = "secret.sops.yaml"
}
