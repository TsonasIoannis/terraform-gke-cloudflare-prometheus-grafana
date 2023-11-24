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

variable "AZDO_PERSONAL_ACCESS_TOKEN" {
  type = string
}
variable "TERRAFORM_GITHUB_PROVIDER" {
  type = string
}
