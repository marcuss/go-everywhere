provider "aws" {
  region = var.aws_region
}

# provider "azure" {
#   features {}
# }
#
# provider "google" {
#   project = var.gcp_project_id
#   region  = var.gcp_region
# }

module "aws_eks" {
  source                 = "./providers/aws"
  region                 = var.aws_region
  github_user            = var.github_user
  github_repo            = var.github_repo
  environment            = var.environment
  cluster_name           = var.aws_eks_cluster_name
  cluster_version        = var.aws_eks_cluster_version
  cloud_provider         = "aws"
  business_unit          = var.business_unit
  local_machine_aws_user = var.local_machine_aws_user
}

# module "azure_aks" {
#   source       = "./providers/azure/aks"
#   region       = var.azure_region
#   github_user  = var.github_user
#   github_repo  = var.github_repo
#   environment  = var.environment
#   cloud_provider  = "azure"
#   # Add other necessary variables
# }
#

# module "gcp_gke" {
#   source       = "./providers/gcp"
#   project_id   = var.gcp_project_id
#   region       = var.gcp_region
#   github_user  = var.github_user
#   github_repo  = var.github_repo
#   environment  = var.environment
#   cloud_provider = "gcp"
#   # Add other necessary variables
# }