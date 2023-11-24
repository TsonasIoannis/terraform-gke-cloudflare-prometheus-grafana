resource "cloudflare_zone" "monitoring" {
  account_id = var.CLOUDFLARE_LIVE_ACCOUNT_ID
  zone       = var.monitoring_domain
}

resource "cloudflare_access_application" "monitoring" {
  account_id       = var.CLOUDFLARE_LIVE_ACCOUNT_ID
  name             = "Monitoring"
  domain           = var.monitoring_domain
  session_duration = "24h"
  type             = "self_hosted"
  allowed_idps     = [cloudflare_access_identity_provider.monitoring_pin_login.id]
}

resource "cloudflare_access_application" "monitoring_grafana" {
  account_id       = var.CLOUDFLARE_LIVE_ACCOUNT_ID
  name             = "Monitoring Grafana"
  domain           = "${helm_release.grafana.name}.${var.monitoring_domain}"
  session_duration = "24h"
  type             = "self_hosted"
  allowed_idps     = [cloudflare_access_identity_provider.monitoring_pin_login.id]
}

resource "cloudflare_access_application" "monitoring_prometheus" {
  account_id       = var.CLOUDFLARE_LIVE_ACCOUNT_ID
  name             = "Monitoring Prometheus"
  domain           = "${helm_release.prometheus.name}.${var.monitoring_domain}"
  session_duration = "24h"
  type             = "self_hosted"
  allowed_idps     = [cloudflare_access_identity_provider.monitoring_pin_login.id]
}

resource "cloudflare_access_application" "monitoring_pushgateway" {
  account_id       = var.CLOUDFLARE_LIVE_ACCOUNT_ID
  name             = "Monitoring PushGateway"
  domain           = "${helm_release.prometheus.name}-pushgateway.${var.monitoring_domain}"
  session_duration = "24h"
  type             = "self_hosted"
  allowed_idps     = [cloudflare_access_identity_provider.monitoring_pin_login.id]
}

resource "cloudflare_access_policy" "monitoring" {
  account_id     = var.CLOUDFLARE_LIVE_ACCOUNT_ID
  application_id = cloudflare_access_application.monitoring.id
  name           = "User Access Monitoring Policy"
  precedence     = "1"
  decision       = "allow"

  include {
    email = var.allowed_users
  }
}

resource "cloudflare_access_policy" "monitoring_grafana" {
  account_id     = var.CLOUDFLARE_LIVE_ACCOUNT_ID
  application_id = cloudflare_access_application.monitoring_grafana.id
  name           = "User Access Monitoring Policy"
  precedence     = "1"
  decision       = "allow"

  include {
    email = var.allowed_users
  }
}

resource "cloudflare_access_policy" "monitoring_grafana_service_tokens" {
  account_id     = var.CLOUDFLARE_LIVE_ACCOUNT_ID
  application_id = cloudflare_access_application.monitoring_grafana.id
  name           = "Service Token Access Monitoring Policy for Terraform"
  precedence     = "10"
  decision       = "non_identity"

  include {
    service_token = [cloudflare_access_service_token.terraform.id]
  }
}

resource "cloudflare_access_policy" "monitoring_prometheus" {
  account_id     = var.CLOUDFLARE_LIVE_ACCOUNT_ID
  application_id = cloudflare_access_application.monitoring_prometheus.id
  name           = "User Access Monitoring Policy"
  precedence     = "1"
  decision       = "allow"

  include {
    email = var.allowed_users
  }
}

resource "cloudflare_access_policy" "monitoring_pushgateway_service_tokens" {
  account_id     = var.CLOUDFLARE_LIVE_ACCOUNT_ID
  application_id = cloudflare_access_application.monitoring_pushgateway.id
  name           = "Service Token Access PushGateway Policy"
  precedence     = "10"
  decision       = "non_identity"

  include {
    service_token = [cloudflare_access_service_token.pushgateway.id]
  }
}

resource "cloudflare_access_identity_provider" "monitoring_pin_login" {
  account_id = var.CLOUDFLARE_LIVE_ACCOUNT_ID
  name       = "Monitoring PIN login"
  type       = "onetimepin"
}

resource "cloudflare_access_service_token" "terraform" {
  account_id = var.CLOUDFLARE_LIVE_ACCOUNT_ID
  name       = "TF app"
}

resource "cloudflare_access_service_token" "pushgateway" {
  account_id = var.CLOUDFLARE_LIVE_ACCOUNT_ID
  name       = "pushgateway clients"
}

resource "random_id" "monitoring_tunnel_secret" {
  byte_length = 35
}


resource "cloudflare_tunnel" "monitoring" {
  account_id = var.CLOUDFLARE_LIVE_ACCOUNT_ID
  name       = "monitoring"
  secret     = random_id.monitoring_tunnel_secret.b64_std
}

resource "cloudflare_tunnel_config" "monitoring" {
  account_id = var.CLOUDFLARE_LIVE_ACCOUNT_ID
  tunnel_id  = cloudflare_tunnel.monitoring.id

  config {
    ingress_rule {
      hostname = "${helm_release.grafana.name}.${var.monitoring_domain}"
      service  = "http://${helm_release.grafana.name}:80"
    }
    ingress_rule {
      hostname = "${helm_release.prometheus.name}.${var.monitoring_domain}"
      service  = "http://${helm_release.prometheus.name}-server:80"
    }
    ingress_rule {
      service = "http_status:404"
    }
  }
}

resource "cloudflare_record" "grafana" {
  zone_id = cloudflare_zone.monitoring.id
  name    = "grafana"
  value   = "${cloudflare_tunnel.monitoring.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "prometheus" {
  zone_id = cloudflare_zone.monitoring.id
  name    = "prometheus"
  value   = "${cloudflare_tunnel.monitoring.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}
