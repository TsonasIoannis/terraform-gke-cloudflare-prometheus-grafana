data "google_client_config" "default" {}

locals {
  connect_gateway = "https://connectgateway.googleapis.com/v1/projects/${google_project.monitoring.number}/locations/global/gkeMemberships/${google_container_cluster.monitoring.name}"
}

provider "kubernetes" {
  host  = local.connect_gateway
  token = data.google_client_config.default.access_token
  alias = "monitoring"
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "gke-gcloud-auth-plugin"
  }
}

provider "helm" {
  alias = "monitoring"
  kubernetes {
    host = local.connect_gateway

    token = data.google_client_config.default.access_token
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "gke-gcloud-auth-plugin"
    }
  }
}

resource "kubernetes_namespace" "monitoring" {
  provider = kubernetes.monitoring
  metadata {
    name = "monitoring"
  }
}

resource "helm_release" "prometheus" {
  provider   = helm.monitoring
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"
  version    = "25.1.0"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  values = [
    file("${path.module}/templates/prometheus-values.yaml")
  ]

  set {
    name  = "podSecurityPolicy.enabled"
    value = true
  }

  set {
    name  = "server.persistentVolume.enabled"
    value = false
  }

  set {
    name  = "server.global.scrape_interval"
    value = "10m"
  }

  # You can provide a map of value using yamlencode. Don't forget to escape the last element after point in the name
  set {
    name = "server\\.resources"
    value = yamlencode({
      limits = {
        cpu    = "200m"
        memory = "50Mi"
      }
      requests = {
        cpu    = "100m"
        memory = "30Mi"
      }
    })
  }
}

resource "helm_release" "prometheus-operator-crds" {
  provider   = helm.monitoring
  name       = "prometheus-operator-crds"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus-operator-crds"
  version    = "6.0.0"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
}

resource "kubernetes_secret" "grafana" {
  provider = kubernetes.monitoring
  metadata {
    name      = "grafana"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  data = {
    admin-user     = "admin"
    admin-password = random_password.grafana.result
  }
}

resource "random_password" "grafana" {
  length = 24
}

resource "helm_release" "grafana" {
  provider   = helm.monitoring
  chart      = "grafana"
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  version    = "6.61.1"

  values = [
    templatefile("${path.module}/templates/grafana-values.yaml", {
      admin_existing_secret = kubernetes_secret.grafana.metadata[0].name
      admin_user_key        = "admin-user"
      admin_password_key    = "admin-password"
      prometheus_svc        = "${helm_release.prometheus.name}-server"
      replicas              = 1
    })
  ]
}
