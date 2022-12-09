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
  }
  required_version = ">= 1.3.0"
}

provider "minio" {
  minio_server   = var.minio_server
  minio_region   = var.minio_region
  minio_user     = var.minio_access_key
  minio_password = var.minio_secret_key
  minio_ssl      = true
}
