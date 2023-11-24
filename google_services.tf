locals {
  gcp_apis = [
    "iam.googleapis.com",                  # Needed for service account import
    "serviceusage.googleapis.com",         # Default
    "servicemanagement.googleapis.com",    # Default
    "iamcredentials.googleapis.com",       # Default
    "storage-api.googleapis.com",          # Default
    "cloudapis.googleapis.com",            # Default
    "cloudtrace.googleapis.com",           # Default
    "storage.googleapis.com",              # Default
    "storage-component.googleapis.com",    # Default
    "sql-component.googleapis.com",        # Default
    "monitoring.googleapis.com",           # Default
    "logging.googleapis.com",              # Default
    "datastore.googleapis.com",            # Default
    "bigquerystorage.googleapis.com",      # Default
    "bigquerymigration.googleapis.com",    # Default
    "bigquery.googleapis.com",             # Default
    "cloudresourcemanager.googleapis.com", # Default
    "compute.googleapis.com",              # Prometheus VPC
    "container.googleapis.com",            # Prometheus VPC
    "gkehub.googleapis.com",               # Connect Gateway
    "connectgateway.googleapis.com",       # Connect Gateway
    "anthos.googleapis.com",               # Connect Gateway - incurs charges
    "dns.googleapis.com",                  # Cloud domains
    "domains.googleapis.com",              # Cloud domains
  ]
}


resource "google_project_service" "terraform" {
  for_each                   = toset(local.gcp_apis)
  project                    = google_project.monitoring.project_id
  service                    = each.key
  disable_dependent_services = true
  disable_on_destroy         = true
}
