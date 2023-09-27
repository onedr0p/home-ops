resource "kubernetes_config_map_v1" "vector_agent" {
  metadata {
    name      = "vector-agent"
    namespace = "default"
    labels = {
      "app.arpa.home/name" = "vector-agent"
    }
  }
  data = {
    "vector.yaml" = "${templatefile(
      "${path.module}/templates/vector.yaml.tftpl", {
        host = var.vector_agent_host,
        port = var.vector_agent_port
      }
    )}"
  }
}

resource "kubernetes_daemon_set_v1" "vector_agent" {
  depends_on = [kubernetes_config_map_v1.vector_agent]
  metadata {
    name      = "vector-agent"
    namespace = "default"
    labels = {
      "app.arpa.home/name" = "vector-agent"
    }
  }
  spec {
    selector {
      match_labels = {
        "app.arpa.home/name" = "vector-agent"
      }
    }
    template {
      metadata {
        labels = {
          "app.arpa.home/name" = "vector-agent"
        }
      }
      spec {
        container {
          name              = "main"
          image             = "docker.io/timberio/vector:0.33.0-debian"
          image_pull_policy = "IfNotPresent"
          args              = ["--config=/etc/vector/vector.yaml"]
          security_context {
            privileged  = true
            run_as_user = 0
          }
          volume_mount {
            name       = "config"
            mount_path = "/etc/vector/"
            read_only  = true
          }
          volume_mount {
            name       = "data"
            mount_path = "/vector-data-dir"
          }
          volume_mount {
            name       = "log"
            mount_path = "/var/log"
            read_only  = true
          }
        }
        host_network = true
        toleration {
          effect   = "NoSchedule"
          operator = "Exists"
        }
        volume {
          name = "config"
          projected {
            default_mode = "0420"
            sources {
              config_map {
                name = "vector-agent"
              }
            }
          }
        }
        volume {
          name = "data"
          empty_dir {}
        }
        volume {
          name = "log"
          host_path {
            path = "/var/log"
          }
        }
      }
    }
  }
}
