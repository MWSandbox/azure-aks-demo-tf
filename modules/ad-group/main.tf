data "azuread_client_config" "current" {}

resource "azuread_group" "this" {
  display_name     = var.name
  description      = var.description
  owners           = [data.azuread_client_config.current.object_id]
  security_enabled = true
  members          = var.members
}
