resource "time_sleep" "wait" {
  depends_on      = [kubernetes_stateful_set_v1.nexus]
  create_duration = "10s"
}

resource "nexus_security_realms" "active_realms" {
  provider = nexus.nas
  depends_on = [
    kubernetes_stateful_set_v1.nexus,
    time_sleep.wait
  ]
  active = [
    "NexusAuthenticatingRealm",
    "NexusAuthorizingRealm",
    "DockerToken"
  ]
}

resource "nexus_security_anonymous" "system" {
  provider = nexus.nas
  depends_on = [
    kubernetes_stateful_set_v1.nexus,
    time_sleep.wait
  ]
  enabled    = true
  user_id    = "anonymous"
  realm_name = "NexusAuthorizingRealm"
}

resource "nexus_repository_docker_hosted" "container_local" {
  provider = nexus.nas
  depends_on = [
    kubernetes_stateful_set_v1.nexus,
    time_sleep.wait
  ]
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

module "docker_proxy_docker_mirror" {
  depends_on = [
    kubernetes_stateful_set_v1.nexus,
    time_sleep.wait
  ]
  source = "./modules/docker_proxy"
  providers = {
    nexus = nexus.nas
  }
  registry_name       = "docker-mirror"
  registry_index_type = "HUB"
  registry_remote_url = "https://registry-1.docker.io"
}

module "docker_proxy_ecr_mirror" {
  depends_on = [
    kubernetes_stateful_set_v1.nexus,
    time_sleep.wait
  ]
  source = "./modules/docker_proxy"
  providers = {
    nexus = nexus.nas
  }
  registry_name       = "ecr-mirror"
  registry_index_type = "REGISTRY"
  registry_remote_url = "https://public.ecr.aws"
}

module "docker_proxy_gcr_mirror" {
  depends_on = [
    kubernetes_stateful_set_v1.nexus,
    time_sleep.wait
  ]
  source = "./modules/docker_proxy"
  providers = {
    nexus = nexus.nas
  }
  registry_name       = "gcr-mirror"
  registry_index_type = "REGISTRY"
  registry_remote_url = "https://gcr.io"
}

module "docker_proxy_ghcr_mirror" {
  depends_on = [
    kubernetes_stateful_set_v1.nexus,
    time_sleep.wait
  ]
  source = "./modules/docker_proxy"
  providers = {
    nexus = nexus.nas
  }
  registry_name       = "ghcr-mirror"
  registry_index_type = "REGISTRY"
  registry_remote_url = "https://ghcr.io"
}

module "docker_proxy_k8s_mirror" {
  depends_on = [
    kubernetes_stateful_set_v1.nexus,
    time_sleep.wait
  ]
  source = "./modules/docker_proxy"
  providers = {
    nexus = nexus.nas
  }
  registry_name       = "k8s-mirror"
  registry_index_type = "REGISTRY"
  registry_remote_url = "https://registry.k8s.io"
}

module "docker_proxy_k8s_gcr_mirror" {
  depends_on = [
    kubernetes_stateful_set_v1.nexus,
    time_sleep.wait
  ]
  source = "./modules/docker_proxy"
  providers = {
    nexus = nexus.nas
  }
  registry_name       = "k8s-gcr-mirror"
  registry_index_type = "REGISTRY"
  registry_remote_url = "https://k8s.gcr.io"
}

module "docker_proxy_quay_mirror" {
  depends_on = [
    kubernetes_stateful_set_v1.nexus,
    time_sleep.wait
  ]
  source = "./modules/docker_proxy"
  providers = {
    nexus = nexus.nas
  }
  registry_name       = "quay-mirror"
  registry_index_type = "REGISTRY"
  registry_remote_url = "https://quay.io"
}

resource "nexus_repository_docker_group" "docker_group" {
  provider = nexus.nas
  depends_on = [
    module.docker_proxy_docker_mirror,
    module.docker_proxy_ecr_mirror,
    module.docker_proxy_gcr_mirror,
    module.docker_proxy_ghcr_mirror,
    module.docker_proxy_k8s_mirror,
    module.docker_proxy_k8s_gcr_mirror,
    module.docker_proxy_quay_mirror
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
      module.docker_proxy_docker_mirror.registry_name,
      module.docker_proxy_ecr_mirror.registry_name,
      module.docker_proxy_gcr_mirror.registry_name,
      module.docker_proxy_ghcr_mirror.registry_name,
      module.docker_proxy_k8s_mirror.registry_name,
      module.docker_proxy_k8s_gcr_mirror.registry_name,
      module.docker_proxy_quay_mirror.registry_name
    ]
  }
  storage {
    blob_store_name                = "default"
    strict_content_type_validation = true
  }
}
