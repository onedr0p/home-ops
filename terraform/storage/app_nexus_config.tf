resource "nexus_security_realms" "active_realms" {
  depends_on = [kubernetes_stateful_set_v1.nexus]

  active = [
    "NexusAuthenticatingRealm",
    "NexusAuthorizingRealm",
    "DockerToken"
  ]
}

resource "nexus_repository_docker_hosted" "container_local" {
  depends_on = [kubernetes_stateful_set_v1.nexus]

  name   = "container-local"
  online = true

  component {
    proprietary_components = false
  }

  docker {
    force_basic_auth = false
    http_port        = 0
    https_port       = 0
    v1_enabled       = false
  }

  storage {
    blob_store_name                = "default"
    strict_content_type_validation = true
    write_policy                   = "ALLOW"
  }
}

resource "nexus_repository_docker_proxy" "docker_mirror" {
  depends_on = [kubernetes_stateful_set_v1.nexus]

  name   = "docker-mirror"
  online = true

  docker {
    force_basic_auth = false
    http_port        = 0
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

resource "nexus_repository_docker_proxy" "ghcr_mirror" {
  depends_on = [kubernetes_stateful_set_v1.nexus]

  name   = "ghcr-mirror"
  online = true

  docker {
    force_basic_auth = false
    http_port        = 0
    https_port       = 0
    v1_enabled       = false
  }

  docker_proxy {
    index_type = "REGISTRY"
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
    remote_url       = "https://ghcr.io"
  }

  storage {
    blob_store_name                = "default"
    strict_content_type_validation = true
  }
}

resource "nexus_repository_docker_proxy" "k8s_mirror" {
  depends_on = [kubernetes_stateful_set_v1.nexus]

  name   = "k8s-mirror"
  online = true

  docker {
    force_basic_auth = false
    http_port        = 0
    https_port       = 0
    v1_enabled       = false
  }

  docker_proxy {
    index_type = "REGISTRY"
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
    remote_url       = "https://registry.k8s.io"
  }

  storage {
    blob_store_name                = "default"
    strict_content_type_validation = true
  }
}

resource "nexus_repository_docker_proxy" "quay_mirror" {
  depends_on = [kubernetes_stateful_set_v1.nexus]

  name   = "quay-mirror"
  online = true

  docker {
    force_basic_auth = false
    http_port        = 0
    https_port       = 0
    v1_enabled       = false
  }

  docker_proxy {
    index_type = "REGISTRY"
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
    remote_url       = "https://quay.io"
  }

  storage {
    blob_store_name                = "default"
    strict_content_type_validation = true
  }
}

resource "nexus_repository_docker_group" "docker_group" {
  depends_on = [
    nexus_repository_docker_proxy.docker_mirror,
    nexus_repository_docker_proxy.ghcr_mirror,
    nexus_repository_docker_proxy.k8s_mirror,
    nexus_repository_docker_proxy.quay_mirror
  ]

  name   = "docker-group"
  online = true

  docker {
    force_basic_auth = false
    http_port        = 3000
    https_port       = 0
    v1_enabled       = false
  }

  group {
    member_names = [
      nexus_repository_docker_proxy.docker_mirror.name,
      nexus_repository_docker_proxy.ghcr_mirror.name,
      nexus_repository_docker_proxy.k8s_mirror.name,
      nexus_repository_docker_proxy.quay_mirror.name
    ]
  }

  storage {
    blob_store_name                = "default"
    strict_content_type_validation = true
  }
}
