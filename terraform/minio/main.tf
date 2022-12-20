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
  minio_server   = "s3.devbu.io"
  minio_region   = "us-east-1"
  minio_user     = var.minio_access_key
  minio_password = var.minio_secret_key
  minio_ssl      = true
}
