resource "azurerm_resource_group" "main" {
  name     = "${var.business_unit}-rg"
  location = var.azure_region
}