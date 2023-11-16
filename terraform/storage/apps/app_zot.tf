resource "kubernetes_config_map_v1" "zot" {
  metadata {
    name      = "zot"
    namespace = "default"
    labels = {
      "app.arpa.home/name" = "zot"
    }
  }
  data = {
    "config.json" = "${file("${path.module}/templates/zot.json.tftpl")}"
  }
}

resource "kubernetes_stateful_set_v1" "zot" {
  metadata {
    name      = "zot"
    namespace = "default"
    labels = {
      "app.arpa.home/name" = "zot"
    }
  }
  spec {
    selector {
      match_labels = {
        "app.arpa.home/name" = "zot"
      }
    }
    service_name = "zot"
    replicas     = 1
    template {
      metadata {
        labels = {
          "app.arpa.home/name" = "zot"
        }
      }
      spec {
        container {
          name              = "main"
          image             = "ghcr.io/project-zot/zot-linux-amd64:v1.4.3"
          image_pull_policy = "IfNotPresent"
          port {
            name           = "http"
            container_port = 5000
            host_port      = 5000
          }
          liveness_probe {
            http_get {
              path = "/v2/"
              port = 5000
            }
            initial_delay_seconds = 30
            period_seconds        = 30
            failure_threshold     = 6
            timeout_seconds       = 10
          }
          readiness_probe {
            http_get {
              path = "/v2/"
              port = 5000
            }
            initial_delay_seconds = 30
            period_seconds        = 30
            failure_threshold     = 6
            timeout_seconds       = 10
          }
          volume_mount {
            name       = "config"
            mount_path = "/var/lib/registry"
          }
          volume_mount {
            name       = "config-file"
            mount_path = "/etc/zot/config.json"
            read_only = true
            sub_path = "config.json"
          }
        }
        volume {
          name = "config"
          host_path {
            path = "/eros/Apps/Zot"
            type = "Directory"
          }
        }
        volume {
          name = "config-file"
          projected {
            default_mode = "0420"
            sources {
              config_map {
                name = "zot"
              }
            }
          }
        }
        security_context {
          run_as_user = 568
          run_as_group = 568
          fs_group = 568
          fs_group_change_policy = "OnRootMismatch"
          supplemental_groups = [
            100
          ]
        }
        toleration {
          effect   = "NoSchedule"
          operator = "Exists"
        }
      }
    }
    update_strategy {
      type = "RollingUpdate"
    }
  }
}

resource "kubernetes_service_v1" "zot" {
  metadata {
    name      = "zot"
    namespace = "default"
    labels = {
      "app.arpa.home/name" = "zot"
    }
  }
  spec {
    selector = {
      "app.arpa.home/name" = "zot"
    }
    port {
      name        = "http"
      port        = 5000
      target_port = 5000
      protocol    = "TCP"
    }
  }
}

resource "kubernetes_ingress_v1" "zot" {
  metadata {
    name      = "zot"
    namespace = "default"
    annotations = {
      "traefik.ingress.kubernetes.io/router.entrypoints" = "web"
    }
    labels = {
      "app.arpa.home/name" = "zot"
    }
  }
  spec {
    ingress_class_name = "traefik"
    rule {
      host = "zot.turbo.ac"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "zot"
              port {
                number = 5000
              }
            }
          }
        }
      }
    }
  }
}
