resource "kubernetes_deployment" "github_exporter" {
  #ts:skip=AC-K8-NS-PO-M-0122 False positive as security context is added
  provider = kubernetes.monitoring
  metadata {
    name = "githubexporter"
    labels = {
      app = "githubexporter"
    }
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }
  spec {
    selector {
      match_labels = {
        app = "githubexporter"
      }
    }
    template {
      metadata {
        labels = {
          app = "githubexporter"
        }
      }
      spec {
        container {
          image             = "githubexporter/github-exporter:1.0.5"
          name              = "github-exporter"
          image_pull_policy = "Always"
          env {
            name  = "ORGS"
            value = "example"
          }
          env {
            name = "GITHUB_TOKEN"
            value_from {
              secret_key_ref {
                name = "exporters"
                key  = "github_pat"
              }
            }
          }
          port {
            container_port = 9171
            host_port      = 9171
            protocol       = "TCP"
          }
          stdin = true
          tty   = true
          security_context {
            allow_privilege_escalation = false
          }
        }
        security_context {
          run_as_user = 1000
        }
        restart_policy                   = "Always"
        termination_grace_period_seconds = 60
      }
    }
  }
}

resource "kubernetes_service" "github_exporter" {
  provider = kubernetes.monitoring
  metadata {
    name        = "githubexporter"
    namespace   = kubernetes_namespace.monitoring.metadata[0].name
    annotations = { "prometheus.io/scrape" : "true" }
  }
  spec {
    selector = {
      app = kubernetes_deployment.github_exporter.metadata[0].labels.app
    }
    port {
      port        = 9171
      target_port = 9171
    }
    type = "ClusterIP"
  }
}

resource "kubernetes_secret" "exporters" {
  provider = kubernetes.monitoring
  metadata {
    name      = "exporters"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }
  data = {
    azdo_pat   = var.AZDO_PERSONAL_ACCESS_TOKEN
    github_pat = var.TERRAFORM_GITHUB_PROVIDER
  }
}

resource "kubernetes_deployment" "azdevops_exporter" {
  #ts:skip=AC-K8-NS-PO-M-0122 False positive as security context is added
  provider = kubernetes.monitoring
  metadata {
    name = "azdevopsexporter"
    labels = {
      app = "azdevopsexporter"
    }
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }
  spec {
    selector {
      match_labels = {
        app = "azdevopsexporter"
      }
    }
    template {
      metadata {
        labels = {
          app = "azdevopsexporter"
        }
      }
      spec {
        container {
          image             = "webdevops/azure-devops-exporter:23.2.0"
          name              = "azdevops-exporter"
          image_pull_policy = "Always"
          env {
            name = "AZURE_DEVOPS_ACCESS_TOKEN"
            value_from {
              secret_key_ref {
                name = "exporters"
                key  = "azdo_pat"
              }
            }
          }
          env {
            name  = "AZURE_DEVOPS_ORGANISATION"
            value = "simedx"
          }
          port {
            container_port = 8080
            host_port      = 8080
            protocol       = "TCP"
          }
          stdin = true
          tty   = true
          security_context {
            allow_privilege_escalation = false
          }
        }
        security_context {
          run_as_user = 1000
        }
        restart_policy                   = "Always"
        termination_grace_period_seconds = 60
      }
    }
  }
}

resource "kubernetes_service" "azdevops_exporter" {
  provider = kubernetes.monitoring
  metadata {
    name        = "azdevopsexporter"
    namespace   = kubernetes_namespace.monitoring.metadata[0].name
    annotations = { "prometheus.io/scrape" : "true" }
  }
  spec {
    selector = {
      app = kubernetes_deployment.azdevops_exporter.metadata[0].labels.app
    }
    port {
      port        = 8080
      target_port = 8080
    }
    type = "ClusterIP"
  }
}
