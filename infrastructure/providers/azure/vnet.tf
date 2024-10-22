resource "azurerm_virtual_network" "main" {
  name                = "${var.business_unit}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    BusinessUnit = var.business_unit
    Environment  = var.environment
  }
}

resource "azurerm_subnet" "public" {
  count               = 2
  name                = "${var.business_unit}-subnet-public-${count.index + 1}"
  resource_group_name = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes    = ["10.0.${count.index}.0/24"]

  service_endpoints   = ["Microsoft.Web", "Microsoft.Storage"]
}

resource "azurerm_subnet" "private" {
  count               = 2
  name                = "${var.business_unit}-subnet-private-${count.index + 1}"
  resource_group_name = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes    = ["10.0.${count.index + 10}.0/24"]

  service_endpoints   = ["Microsoft.Web", "Microsoft.Storage"]
}