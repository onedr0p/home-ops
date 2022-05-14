terraform {

  backend "remote" {
    organization = "onedr0p"
    workspaces {
      name = "home-nexus"
    }
  }

  required_providers {
    nexus = {
      source  = "datadrivers/nexus"
      version = "1.18.0"
    }
    sops = {
      source  = "carlpett/sops"
      version = "0.7.1"
    }
  }
}

data "sops_file" "minio_secrets" {
  source_file = "secret.sops.yaml"
}

provider "nexus" {
  insecure = false
  url      = data.sops_file.minio_secrets.data["nexus_address"]
  username = data.sops_file.minio_secrets.data["nexus_username"]
  password = data.sops_file.minio_secrets.data["nexus_password"]
}

resource "nexus_repository_docker_hosted" "docker_local" {
  name   = "docker-local"
  online = true

  component {
    proprietary_components = false
  }

  docker {
    force_basic_auth = false
    http_port        = 8082
    https_port       = 0
    v1_enabled       = false
  }

  storage {
    blob_store_name                = "default"
    strict_content_type_validation = true
    write_policy                   = "ALLOW"
  }
}

resource "nexus_repository_docker_proxy" "docker_io_mirror" {
  name   = "docker-io-mirror"
  online = true

  docker {
    force_basic_auth = false
    http_port        = 8083
    https_port       = 0
    v1_enabled       = false
  }

  docker_proxy {
    index_type = "HUB"
  }

  http_client {
    auto_block = true
    blocked    = false
  }

  negative_cache {
    enabled = true
    ttl     = 1440
  }

  proxy {
    content_max_age  = 1440
    metadata_max_age = 1440
    remote_url       = "https://registry-1.docker.io"
  }

  storage {
    blob_store_name                = "default"
    strict_content_type_validation = true
  }
}

resource "nexus_security_realms" "active_realms" {
  active = [
    "NexusAuthenticatingRealm",
    "NexusAuthorizingRealm",
    "DockerToken"
  ]
}
