variable "monitoring_domain" {
  default = "example.live"
  type    = string
}

variable "CLOUDFLARE_LIVE_ACCOUNT_ID" {
  type = string
}

variable "allowed_users" {
  type = list(string)

  default = [
    "example1@test.com",
    "example2@test.com",
  ]
}
