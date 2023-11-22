data "google_organization" "example" {
  organization = "organizations/org_id"
}

resource "google_folder" "example" {
  display_name = "Example"
  parent       = data.google_organization.example.name
}

resource "google_project" "monitoring" {
  name                = "Monitoring"
  project_id          = "project-id"
  org_id              = "org_id"
  auto_create_network = false
  timeouts {}
}
