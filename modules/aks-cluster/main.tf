terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14.0"
    }
  }

  required_version = ">= 1.4.4"
}

provider "kubectl" {
  config_path = "./../kubeconfig"
}

data "http" "my_ip" {
  url = "http://icanhazip.com"
}

resource "azurerm_kubernetes_cluster" "this" {
  #checkov:skip=CKV_AZURE_115:Private cluster setup will be enabled later on, currently access to cluster limited by own IP address
  #checkov:skip=CKV_AZURE_6:IP range is restricted, but terraform config format changed - checkov rule needs update
  name                              = var.name
  location                          = var.resource_group.location
  resource_group_name               = var.resource_group.name
  dns_prefix                        = var.dns_prefix
  disk_encryption_set_id            = var.disk_encryption_set_id
  local_account_disabled            = true
  azure_policy_enabled              = true
  role_based_access_control_enabled = true

  api_server_access_profile {
    authorized_ip_ranges = ["${chomp(data.http.my_ip.response_body)}/32"]
  }


  default_node_pool {
    name           = "default"
    node_count     = "1"
    vm_size        = "standard_d2_v3"
    vnet_subnet_id = var.subnet_id
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
    network_policy = "calico"
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
  }

  azure_active_directory_role_based_access_control {
    managed                = true
    admin_group_object_ids = [var.admin_group_id]
    azure_rbac_enabled     = false
  }
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = var.name
  location            = var.resource_group.location
  resource_group_name = var.resource_group.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "local_file" "kubeconfig" {
  depends_on = [azurerm_kubernetes_cluster.this]
  filename   = var.kube_config_location
  content    = azurerm_kubernetes_cluster.this.kube_config_raw
}