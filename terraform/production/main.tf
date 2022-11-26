terraform {
  cloud {
    hostname     = "app.terraform.io"
    organization = "onedr0p"
    workspaces {
      name = "arpa-home"
    }
  }
  required_providers {
    minio = {
      source  = "aminueza/minio"
      version = "1.9.1"
    }
  }
  required_version = ">= 1.3.0"
}

provider "minio" {
  alias          = "cluster"
  minio_server   = var.minio_server
  minio_region   = var.minio_region
  minio_user     = var.minio_access_key
  minio_password = var.minio_secret_key
  minio_ssl      = true
}

module "minio" {
  source = "../modules/minio"
  providers = {
    minio = minio.cluster
  }
}
