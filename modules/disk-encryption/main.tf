data "azurerm_client_config" "current" {}
data "http" "my_ip" {
  url = "http://icanhazip.com"
}


resource "azurerm_key_vault" "this" {
  name                        = var.unique_key_vault_name
  location                    = var.resource_group.location
  resource_group_name         = var.resource_group.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "premium"
  enabled_for_disk_encryption = true
  purge_protection_enabled    = true
  soft_delete_retention_days  = 7

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    ip_rules       = ["${chomp(data.http.my_ip.response_body)}/32"]
  }
}

resource "azurerm_key_vault_access_policy" "aks_access" {
  key_vault_id = azurerm_key_vault.this.id

  tenant_id = azurerm_disk_encryption_set.this.identity.0.tenant_id
  object_id = azurerm_disk_encryption_set.this.identity.0.principal_id

  key_permissions = [
    "Create",
    "Delete",
    "Get",
    "Purge",
    "Recover",
    "Update",
    "List",
    "Decrypt",
    "Sign",
    "UnwrapKey",
    "WrapKey"
  ]
}

resource "azurerm_key_vault_access_policy" "user_access" {
  key_vault_id = azurerm_key_vault.this.id

  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = data.azurerm_client_config.current.object_id

  key_permissions = [
    "Create",
    "Delete",
    "Get",
    "Purge",
    "Recover",
    "Update",
    "List",
    "Decrypt",
    "Sign",
    "GetRotationPolicy"
  ]
}

resource "azurerm_key_vault_key" "this" {
  name         = var.name
  key_vault_id = azurerm_key_vault.this.id
  key_type     = "RSA"
  key_size     = 2048

  #checkov:skip=CKV_AZURE_40:Key rotation disabled due to cost reasons
  #checkov:skip=CKV_AZURE_112:HSM not used due to cost reasons
  depends_on = [
    azurerm_key_vault_access_policy.user_access
  ]

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]
}

resource "azurerm_disk_encryption_set" "this" {
  name                = var.name
  resource_group_name = var.resource_group.name
  location            = var.resource_group.location
  key_vault_key_id    = azurerm_key_vault_key.this.id

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "encryption_role" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Crypto Service Encryption User"
  principal_id         = azurerm_disk_encryption_set.this.identity.0.principal_id
}
