terraform {
  cloud {
    hostname     = "app.terraform.io"
    organization = "onedr0p"
    workspaces {
      name = "arpa-home-storage"
    }
  }
  required_providers {
    nexus = {
      source  = "datadrivers/nexus"
      version = "1.21.2"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.16.1"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.9.1"
    }
  }
  required_version = ">= 1.3.0"
}

provider "kubernetes" {
  host                   = var.kubernetes_host
  client_certificate     = base64decode(var.kubernetes_client_certificate)
  client_key             = base64decode(var.kubernetes_client_key)
  cluster_ca_certificate = base64decode(var.kubernetes_cluster_ca_certificate)
}

provider "nexus" {
  alias    = "nas"
  insecure = true
  url      = "http://nexus.turbo.ac"
  username = "admin"
  password = "this-is-nothing-important"
}
