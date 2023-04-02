resource "azurerm_virtual_network" "aks" {
  name                = "aks-demo-network"
  location            = var.resource_group.location
  resource_group_name = var.resource_group.name
  address_space       = ["10.1.0.0/16"]
}

resource "azurerm_subnet" "primary" {
  name                 = "aks-demo-primary-subnet"
  virtual_network_name = azurerm_virtual_network.aks.name
  resource_group_name  = var.resource_group.name
  address_prefixes     = ["10.1.0.0/22"]
}