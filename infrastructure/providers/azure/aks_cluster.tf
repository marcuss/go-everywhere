resource "azurerm_kubernetes_cluster" "main" {
  name                = var.azure_aks_cluster_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "${var.azure_aks_cluster_name}-dns"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_D2_v2"
  }

  identity {
    type = "SystemAssigned"
  }

  kubernetes_version = var.azure_aks_cluster_version

  tags = {
    Environment  = var.environment
    BusinessUnit = var.business_unit
  }
}