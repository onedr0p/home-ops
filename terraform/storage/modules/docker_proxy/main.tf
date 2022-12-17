terraform {
  required_providers {
    nexus = {
      source = "datadrivers/nexus"
    }
  }
}

resource "nexus_repository_docker_proxy" "mirror" {
  name   = var.registry_name
  online = true
  docker {
    force_basic_auth = false
    http_port        = 0
    https_port       = 0
    v1_enabled       = false
  }
  docker_proxy {
    index_type = var.registry_index_type
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
    remote_url       = var.registry_remote_url
  }
  storage {
    blob_store_name                = "default"
    strict_content_type_validation = true
  }
}
