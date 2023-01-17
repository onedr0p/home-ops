resource "kubernetes_stateful_set_v1" "nexus" {
  metadata {
    name      = "nexus"
    namespace = "default"
    labels = {
      "app.arpa.home/name" = "nexus"
    }
  }
  spec {
    selector {
      match_labels = {
        "app.arpa.home/name" = "nexus"
      }
    }
    service_name = "nexus"
    replicas     = 1
    template {
      metadata {
        labels = {
          "app.arpa.home/name" = "nexus"
        }
      }
      spec {
        container {
          name              = "main"
          image             = "docker.io/sonatype/nexus3:3.45.1"
          image_pull_policy = "IfNotPresent"
          env {
            name  = "INSTALL4J_ADD_VM_PARAMS"
            value = "-Xms2703M -Xmx2703M -XX:MaxDirectMemorySize=2703M -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap -Djava.util.prefs.userRoot=/nexus-data/javaprefs"
          }
          env {
            name  = "NEXUS_SECURITY_INITIAL_PASSWORD"
            value = var.nexus_password
          }
          env {
            name  = "NEXUS_SECURITY_RANDOMPASSWORD"
            value = false
          }
          port {
            name           = "http"
            container_port = 8081
            host_port      = 8081
          }
          port {
            name           = "mirror"
            container_port = 3000
            host_port      = 3000
          }
          liveness_probe {
            http_get {
              path = "/"
              port = 8081
            }
            initial_delay_seconds = 30
            period_seconds        = 30
            failure_threshold     = 6
            timeout_seconds       = 10
          }
          readiness_probe {
            http_get {
              path = "/"
              port = 8081
            }
            initial_delay_seconds = 30
            period_seconds        = 30
            failure_threshold     = 6
            timeout_seconds       = 10
          }
          volume_mount {
            name       = "nexus-data"
            mount_path = "/nexus-data"
          }
          resources {
            requests = {
              cpu    = "4"
              memory = "8Gi"
            }
            limits = {
              cpu    = "4"
              memory = "8Gi"
            }
          }
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
    volume_claim_template {
      metadata {
        name = "nexus-data"
      }
      spec {
        access_modes       = ["ReadWriteOnce"]
        storage_class_name = "local-path"

        resources {
          requests = {
            storage = "50Gi"
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "nexus" {
  metadata {
    name      = "nexus"
    namespace = "default"
    labels = {
      "app.arpa.home/name" = "nexus"
    }
  }
  spec {
    selector = {
      "app.arpa.home/name" = "nexus"
    }
    port {
      name        = "http"
      port        = 8081
      target_port = 8081
      protocol    = "TCP"
    }
    port {
      name        = "mirror"
      port        = 3000
      target_port = 3000
      protocol    = "TCP"
    }
  }
}

resource "kubernetes_ingress_v1" "nexus" {
  metadata {
    name      = "nexus"
    namespace = "default"
    annotations = {
      "traefik.ingress.kubernetes.io/router.entrypoints" = "web"
    }
    labels = {
      "app.arpa.home/name" = "nexus"
    }
  }
  spec {
    ingress_class_name = "traefik"
    rule {
      host = "nexus.turbo.ac"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "nexus"
              port {
                number = 8081
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_ingress_v1" "mirror" {
  metadata {
    name      = "mirror"
    namespace = "default"
    annotations = {
      "traefik.ingress.kubernetes.io/router.entrypoints" = "web"
    }
    labels = {
      "app.arpa.home/name" = "nexus"
    }
  }
  spec {
    ingress_class_name = "traefik"
    rule {
      host = "mirror.turbo.ac"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "nexus"
              port {
                number = 3000
              }
            }
          }
        }
      }
    }
  }
}
