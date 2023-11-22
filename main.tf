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
      version = "2.23.0"
    }
    helm = {
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
