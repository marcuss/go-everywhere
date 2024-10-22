provider "aws" {
  region = var.aws_region
}

provider "azurerm" {
  features {}
}

# Conditional module for AWS deployment
module "aws_eks" {
  source                 = "./providers/aws"
  region                 = var.aws_region
  github_user            = var.github_user
  github_repo            = var.github_repo
  environment            = var.environment
  cluster_name           = var.aws_eks_cluster_name
  cluster_version        = var.aws_eks_cluster_version
  business_unit          = var.business_unit
  local_machine_aws_user = var.local_machine_aws_user
  count                  = var.deploy_aws ? 1 : 0
}

# Conditional module for Azure deployment
module "azure_aks" {
  source                   = "./providers/azure"
  github_user              = var.github_user
  github_repo              = var.github_repo
  environment              = var.environment
  business_unit            = var.business_unit
  azure_aks_cluster_name   = var.aws_eks_cluster_name
  azure_aks_cluster_version = var.azure_aks_cluster_version
  local_machine_azure_user = var.local_machine_azure_user
  count                    = var.deploy_azure ? 1 : 0
}

# module "gcp_gke" {
#   source       = "./providers/gcp"
#   count        = contains(var.selected_providers, "gcp") ? 1 : 0
#   project_id   = var.gcp_project_id
#   region       = var.gcp_region
#   github_user  = var.github_user
#   github_repo  = var.github_repo
#   environment  = var.environment
#   # Add other necessary variables
#   providers        = { google = google }
# }