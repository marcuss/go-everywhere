output "azure_region" {
  description = "The Azure region where resources were deployed"
  value       = var.azure_region
}

output "azure_resource_group_name" {
  description = "The name of the Azure resource group"
  value       = azurerm_resource_group.main.name
}

output "azure_aks_cluster_name" {
  description = "The name of the Azure AKS cluster"
  value       = azurerm_kubernetes_cluster.main.name
}

output "azure_aks_cluster_endpoint" {
  description = "Endpoint for AKS control plane"
  value       = azurerm_kubernetes_cluster.main.kube_config.0.host
}

output "client_certificate" {
  value     = azurerm_kubernetes_cluster.main.kube_config[0].client_certificate
  sensitive = true
}

output "kube_config" {
  value     = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive = true
}