terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.7.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "4.17.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.23.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.11.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.5.1"
    }
    grafana = {
      source  = "grafana/grafana"
      version = "2.3.3"
    }
  }
}


provider "google" {
}

provider "cloudflare" {
}

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
    host  = local.connect_gateway
    token = data.google_client_config.default.access_token
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "gke-gcloud-auth-plugin"
    }
  }
}
