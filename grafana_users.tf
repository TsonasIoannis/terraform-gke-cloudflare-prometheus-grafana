# These are not going to be admin accounts, so a memorable password is preferred
resource "random_pet" "simple-password" {
  for_each = toset(["johndoe", "janedoe"])
  length   = 3
}

resource "grafana_user" "johndoe" {
  provider = grafana.monitoring
  email    = "johndoe@test.com"
  name     = "John Doe"
  login    = "johndoe"
  password = random_pet.simple-password["johndoe"].id
  is_admin = false
}

resource "grafana_user" "janedoe" {
  provider = grafana.monitoring
  email    = "janedoe@test.com"
  name     = "Jane Doe"
  login    = "janedoe"
  password = random_pet.simple-password["janedoe"].id
  is_admin = false
}
