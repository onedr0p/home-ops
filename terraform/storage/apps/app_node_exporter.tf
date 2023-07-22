resource "kubernetes_daemon_set_v1" "node_exporter" {
  metadata {
    name      = "node-exporter"
    namespace = "default"
    labels = {
      "app.arpa.home/name" = "node-exporter"
    }
  }
  spec {
    selector {
      match_labels = {
        "app.arpa.home/name" = "node-exporter"
      }
    }
    template {
      metadata {
        labels = {
          "app.arpa.home/name" = "node-exporter"
        }
      }
      spec {
        container {
          name              = "main"
          image             = "quay.io/prometheus/node-exporter:v1.6.1"
          image_pull_policy = "IfNotPresent"
          args = [
            "--path.procfs=/host/proc",
            "--path.rootfs=/rootfs",
            "--path.sysfs=/host/sys",
            "--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)"
          ]
          port {
            name           = "http"
            container_port = 9100
            host_port      = 9100
          }
          security_context {
            privileged  = true
            run_as_user = 0
          }
          volume_mount {
            name       = "proc"
            mount_path = "/host/proc"
            read_only  = true
          }
          volume_mount {
            name       = "sys"
            mount_path = "/host/sys"
            read_only  = true
          }
          volume_mount {
            name       = "root"
            mount_path = "/rootfs"
            read_only  = true
          }
        }
        host_network = true
        toleration {
          effect   = "NoSchedule"
          operator = "Exists"
        }
        volume {
          name = "proc"
          host_path {
            path = "/proc"
          }
        }
        volume {
          name = "sys"
          host_path {
            path = "/sys"
          }
        }
        volume {
          name = "root"
          host_path {
            path = "/"
          }
        }
      }
    }
  }
}
