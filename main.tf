terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.79.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.15.0"
    }
  }

  required_version = ">= 1.5"
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

resource "azurerm_resource_group" "this" {
  name     = var.name
  location = "westeurope"
}

locals {
  resource_group_object = {
    name     = azurerm_resource_group.this.name
    location = azurerm_resource_group.this.location
  }
}

data "azuread_client_config" "current" {}

module "networking" {
  source = "./modules/networking"

  resource_group = local.resource_group_object
  name           = var.name
}

module "disk_encryption" {
  source = "./modules/disk-encryption"

  name                  = var.name
  unique_key_vault_name = var.key_vault_name
  resource_group        = local.resource_group_object
}

module "admin_group" {
  source = "./modules/ad-group"

  aks_id      = module.aks_cluster.id
  name        = "aks-admin"
  description = "Group members will receive cluster-admin role in kubernetes rbac"
  members     = concat(["${data.azuread_client_config.current.object_id}"], var.admin_group_members)
}

module "aks_cluster" {
  source = "./modules/aks-cluster"

  resource_group         = local.resource_group_object
  disk_encryption_set_id = module.disk_encryption.disk_encryption_set_id
  admin_group_id         = module.admin_group.id
  subnet_id              = module.networking.subnet_id
  dns_prefix             = var.dns_prefix
  name                   = var.name
  kube_config_location   = var.kube_config_location
}