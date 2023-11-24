resource "google_compute_network" "monitoring-vpc" {
  project                 = google_project.monitoring.project_id
  name                    = "monitoring-vpc"
  routing_mode            = "GLOBAL"
  auto_create_subnetworks = false
}

# Subnet
resource "google_compute_subnetwork" "monitoring-subnet" {
  project                  = google_project.monitoring.project_id
  name                     = "monitoring-subnet"
  region                   = "europe-west2"
  network                  = google_compute_network.monitoring-vpc.id
  ip_cidr_range            = "10.0.1.0/24"
  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "monitoring-services"
    ip_cidr_range = "10.10.0.0/24"
  }
  secondary_ip_range {
    range_name    = "monitoring-pods"
    ip_cidr_range = "10.20.0.0/22"
  }
}

# NAT Gateway (needed to pull images outside of gcr)
resource "google_compute_router" "monitoring-router" {
  project = google_project.monitoring.project_id
  name    = "monitoring-router"
  network = google_compute_network.monitoring-vpc.id
  region  = "europe-west2"
}

resource "google_compute_router_nat" "monitoring-nat" {
  project                            = google_project.monitoring.project_id
  region                             = "europe-west2"
  name                               = "monitoring-nat"
  router                             = google_compute_router.monitoring-router.name
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  min_ports_per_vm                   = "64"
  udp_idle_timeout_sec               = "30"
  icmp_idle_timeout_sec              = "30"
  tcp_established_idle_timeout_sec   = "1200"
  tcp_transitory_idle_timeout_sec    = "30"
  tcp_time_wait_timeout_sec          = "120"
  enable_dynamic_port_allocation     = false
}

# GKE cluster
resource "google_container_cluster" "monitoring" {
  project            = google_project.monitoring.project_id
  name               = "monitoring"
  location           = "europe-west2-a"
  resource_labels    = {}
  min_master_version = "1.26.2-gke.1000"

  remove_default_node_pool = true
  initial_node_count       = 1

  network    = google_compute_network.monitoring-vpc.name
  subnetwork = google_compute_subnetwork.monitoring-subnet.name

  ip_allocation_policy {
    cluster_secondary_range_name  = "monitoring-pods"
    services_secondary_range_name = "monitoring-services"
  }

  workload_identity_config {
    workload_pool = "${google_project.monitoring.project_id}.svc.id.goog"
  }

  master_authorized_networks_config {
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = true
    # Not sure how this value is set
    # Documentation: specifies an internal IP address range for the control plane
    master_ipv4_cidr_block = "10.1.0.0/28"
  }

  node_config {
    service_account = google_service_account.monitoring.email
  }

  lifecycle {
    ignore_changes = [node_config]
  }
}

resource "google_service_account" "monitoring" {
  project      = google_project.monitoring.project_id
  account_id   = "monitoring"
  display_name = "Monitoring Service Account"
}

locals {
  monitoring_service_account_roles = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/stackdriver.resourceMetadata.writer",
    "roles/storage.objectViewer",
    "roles/artifactregistry.reader"
  ]
}

resource "google_project_iam_member" "monitoring_service_account-roles" {
  for_each = toset(local.monitoring_service_account_roles)

  project = google_project.monitoring.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.monitoring.email}"
}

# Separately Managed Node Pool
resource "google_container_node_pool" "monitoring-nodes" {
  name       = google_container_cluster.monitoring.name
  location   = "europe-west2-a"
  cluster    = google_container_cluster.monitoring.name
  node_count = 1

  node_config {
    resource_labels = {}
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    labels = {
      env = google_project.monitoring.project_id
    }

    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    preemptible  = false
    machine_type = "e2-medium"
  }
}

resource "google_gke_hub_membership" "monitoring" {
  project       = google_project.monitoring.project_id
  membership_id = "monitoring"

  endpoint {
    gke_cluster {
      resource_link = "//container.googleapis.com/${google_container_cluster.monitoring.id}"
    }
  }
  authority {
    issuer = "https://container.googleapis.com/v1/${google_container_cluster.monitoring.id}"
  }
}
