resource "grafana_folder" "ops" {
  provider = grafana.monitoring
  title    = "Ops"
}

resource "grafana_dashboard" "ops_github" {
  provider = grafana.monitoring

  folder    = grafana_folder.ops.id
  overwrite = true

  config_json = templatefile("dashboards/github_basic.json", {
    title   = "GitHub"
    refresh = "5m"
  })
}

resource "grafana_playlist" "ops_all" {
  provider = grafana.monitoring

  interval = "2m"
  name     = "All Ops"

  item {
    order = 1
    title = "GitHub" # TODO get from json file
  }
}

output "ops_github_dashboard_url" {
  value = grafana_dashboard.ops_github.url
}

resource "grafana_folder" "sandbox" {
  provider = grafana.monitoring
  title    = "_sandbox"
}

resource "grafana_team" "grafana-dev-team" {
  provider = grafana.monitoring
  name     = "Dashboard Dev Team"
  email    = "operations@test.com"

  members = [
    "johndoe@test.com",
    "janedoe@test.com",
  ]
}

resource "grafana_folder_permission" "sandbox_dev_permission" {
  provider   = grafana.monitoring
  folder_uid = grafana_folder.sandbox.uid
  permissions {
    team_id    = grafana_team.grafana-dev-team.id
    permission = "Edit"
  }
}
