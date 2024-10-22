variable "local_machine_azure_user" {
  description = "The name of the local machine's Azure user"
  type        = string
}

variable "environment" {
  description = "The environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "github_user" {
  description = "GitHub user name"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

variable "azure_region" {
  description = "Azure region"
  type        = string
  default     = "East US 2"
}

variable "azure_aks_cluster_name" {
  description = "The name of the Azure AKS cluster"
  type        = string
}

variable "azure_aks_cluster_version" {
  description = "The Kubernetes version for the Azure AKS cluster"
  type        = string
}

variable "business_unit" {
  description = "Prefix or value to tag resources"
  type        = string
}
