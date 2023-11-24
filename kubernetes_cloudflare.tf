resource "kubernetes_deployment" "cloudflared_monitoring" {
  #ts:skip=AC-K8-NS-PO-M-0122 False positive as security context is added
  provider = kubernetes.monitoring
  metadata {
    name = "cloudflared"
    labels = {
      app = "cloudflared"
    }
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }
  spec {
    selector {
      match_labels = {
        app = "cloudflared"
      }
    }
    template {
      metadata {
        labels = {
          app = "cloudflared"
        }
      }
      spec {
        volume {
          name = "config"
          config_map {
            name = "cloudflared"
          }
        }
        container {
          image             = "cloudflare/cloudflared:latest"
          name              = "cloudflaredcontainer"
          image_pull_policy = "Always"
          args              = ["tunnel", "--config", "/etc/cloudflared/config/config.yaml", "run", "--token=${cloudflare_tunnel.monitoring.tunnel_token}"]
          security_context {
            allow_privilege_escalation = false
          }
          volume_mount {
            name       = "config"
            mount_path = "/etc/cloudflared/config"
            read_only  = true
          }
          liveness_probe {
            http_get {
              path = "/ready"
              port = "2000"
            }
            failure_threshold     = 1
            initial_delay_seconds = 10
            period_seconds        = 10
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

resource "kubernetes_config_map" "cloudflared" {
  provider = kubernetes.monitoring
  metadata {
    name      = "cloudflared"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  data = {
    "config.yaml" = <<EOT
# Name of the tunnel you want to run
tunnel: ${cloudflare_tunnel.monitoring.id}
# credentials-file: /etc/cloudflared/creds/credentials.json
# Serves the metrics server under /metrics and the readiness server under /ready
metrics: 0.0.0.0:2000
# Autoupdates applied in a k8s pod will be lost when the pod is removed or restarted, so
# autoupdate doesn't make sense in Kubernetes. However, outside of Kubernetes, we strongly
# recommend using autoupdate.
no-autoupdate: true
EOT
  }
}
